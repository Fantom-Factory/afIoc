
** Use to create an IoC `Registry`. Modules may be added manually, defined by 
** [meta-data]`sys::Pod.meta` in dependent pods or defined by [index properties]`docLang::Env#index`
class RegistryBuilder {
	private const static Log 	logger 		:= Utils.getLog(RegistryBuilder#)
	
	private BuildCtx	ctx 		:= BuildCtx("Building IoC Registry")
	private OneShotLock lock		:= OneShotLock(IocMessages.registryBuilt)
	private ModuleDef[]	moduleDefs	:= [,]
	private Str:Obj		options

	** Create a 'RegistryBuilder'. 
	** 
	** Builder 'options' are reserved for future use. 
	new make([Str:Obj]? reserved := null) {
		reserved = reserved?.rw ?: Utils.makeMap(Str#, Obj#)
		if (!reserved.caseInsensitive)
			reserved = Utils.makeMap(Str#, Obj#).addAll(reserved)
		
		if (!reserved.containsKey("suppressLogging"))
			reserved.add("suppressLogging", false)

		this.options = reserved

		addModule(IocModule#)
	}

	** Adds a module to the registry
	This addModule(Type moduleType) {
		(RegistryBuilder) Utils.stackTraceFilter |->RegistryBuilder| {		
			ctx.track("Adding module definition for '$moduleType.qname'") |->| {
				lock.check
				if (moduleType != IocModule# && !options["suppressLogging"] && !moduleTypes.contains(moduleType))
					logger.info("Adding module definition for $moduleType.qname")

				ctx.withModule(moduleType) |->| {			
					if (moduleDefs.find { it.moduleType == moduleType } != null) {
						// Debug because sometimes you can't help adding the same module twice (via dependencies)
						// afBedSheet is a prime example
						logger.debug(IocMessages.moduleAlreadyAdded(moduleType))
						return
					}

					moduleDef := ModuleDefImpl(ctx.tracker, moduleType)
					addModuleDef(moduleDef)
					
					if (moduleType.hasFacet(SubModule#)) {
						subModule := (SubModule) Type#.method("facet").callOn(moduleType, [SubModule#])	// Stoopid F4
						ctx.track("Found SubModule facet on $moduleType.qname : $subModule.modules") |->| {
							subModule.modules.each { 
								addModule(it)
							}
						}
					} else
						ctx.log("No SubModules found")
				}
			}
			return this
		}
	}

	** Adds many modules to the registry
	This addModules(Type[] moduleTypes) {
		(RegistryBuilder) Utils.stackTraceFilter |->Obj| {		
			lock.check
			moduleTypes.each |moduleType| {
				addModule(moduleType)
			}
			return this
		}
	}

	** Checks all dependencies of the given [pod]`sys::Pod` for the meta-data key 'afIoc.module' 
	** which defines the qualified name of a module to load.
	This addModulesFromDependencies(Pod pod, Bool addTransitiveDependencies := true) {
		(RegistryBuilder) Utils.stackTraceFilter |->Obj| {
			if (!options["suppressLogging"])
				logger.info("Adding modules from dependencies of '$pod.name'")
			addModulesFromDependenciesRecursive(pod, addTransitiveDependencies)
			return this
		}
	}

	** Looks for all index properties of the key 'afIoc.module' which defines a qualified name of 
	** a module to load.
	This addModulesFromIndexProperties() {
		(RegistryBuilder) Utils.stackTraceFilter |->Obj| {		
			if (!options["suppressLogging"])
				logger.info("Adding modules from index properties")
			ctx.track("Adding modules from index properties") |->| {
				lock.check
				moduleNames := Env.cur.index("afIoc.module")
				moduleNames.each {
					addModuleFromTypeName(it)
				}
				if (moduleNames.isEmpty)
					ctx.log("No modules found")
			}
			return this
		}
	}

	** Returns a list of modules types currently held by this builder.
	Type[] moduleTypes() {
		moduleDefs.map { it.moduleType }
	}
	
	** Constructs and returns the registry; this may only be done once. The caller is responsible 
	** for invoking `Registry.startup`
	** 
	** Options are passed to the registry to specify extra behaviour:
	**  -  'logServiceCreation': Bool specifies if each service creation should be logged to INFO. 
	** 		Default is 'false'. For extensive debug info, use 
	** 		[IocHelper.debugOperation()]`IocHelper.debugOperation`.
	**  -  'disableProxies': Bool specifies if all proxy generation for mixin fronted services  
	** 		should be disabled. Default is 'false'.
	**  -  'suppressStartupServiceList': Bool specifies if the service list should be displayed on 
	** 		startup. Default is 'false'.
	**  -  'suppressStartupBanner': Bool specifies if the Alien-Factory banner should be displayed  
	** 		on startup. Default is 'false'.
	** 
	** Other options may also be passed in and can later be retrieved from the `RegistryOptions` 
	** service. 
    Registry build([Str:Obj?]? options := null) {
		Utils.stackTraceFilter |->Obj| {
			lock.lock

			options = options?.rw ?: Utils.makeMap(Str#, Obj?#)
			
			defaults := Utils.makeMap(Str#, Obj#).addAll([
				"logServiceCreation"		: false,
				"disableProxies"			: false,
				"suppressStartupServiceList": false,
				"suppressStartupBanner"		: false,
				"bannerText"				: "Alien-Factory IoC v$typeof.pod.version",
				"appName"					: "Ioc",				
			])

			defaults.each |val, key| {
				optType := options[key]?.typeof
				if (optType != null && optType != val.typeof)
					throw IocErr(IocMessages.invalidRegistryValue(key, optType, val.typeof))
			}

	        registry := RegistryImpl(ctx.tracker, moduleDefs, defaults.setAll(options))
			ctx.tracker.end
			return registry
		}
    }
	
	// ---- Private Methods -----------------------------------------------------------------------

	private Type[] addModulesFromDependenciesRecursive(Pod pod, Bool addTransitiveDependencies) {
		ctx.track("Adding modules from dependencies of '$pod.name'") |->Type[]| {
			lock.check

			Type?[] modTypes := [,]
		
			// don't forget me!
			ctx.withPod(pod) |->| {
				modType := addModuleFromPod(pod)
				if (modType != null)
					modTypes.add(modType)

				pod.depends.each {
					dependency := Pod.find(it.name)
					ctx.withPod(dependency) |->| {
						modType = addModuleFromPod(dependency)
						if (modType != null)
							modTypes.add(modType)

						if (addTransitiveDependencies) {
							mods := ctx.track("Adding transitive dependencies for '$dependency.name'") |->Obj| {
								deps := addModulesFromDependenciesRecursive(dependency, addTransitiveDependencies)
								if (deps.isEmpty)
									ctx.log("No transitive dependencies found")
								return deps
							} 
							modTypes.addAll(mods)
						} else
							ctx.log("Not looking for transitive dependencies")
					}
				}

				if (modTypes.isEmpty)
					ctx.log("No modules found")				
			}

			return modTypes
		}
	}	
	
	private Type? addModuleFromPod(Pod pod) {
		qname := pod.meta[IocConstants.podMetaModuleName]
		if (qname != null) {
			return ctx.track("Pod '$pod.name' defines module $qname") |->Obj| {
				return addModuleFromTypeName(qname)
			}
		}
		return null
	}

	private Type addModuleFromTypeName(Str moduleTypeName) {
		moduleType := Type.find(moduleTypeName)
		addModule(moduleType)
		return moduleType
	}

	private This addModuleDef(ModuleDef moduleDef) {
		this.moduleDefs.add(moduleDef)
		return this
	}
}

internal class BuildCtx {
	private Pod[] 		podStack 		:= [,]
	private Type[] 		moduleStack 	:= [,]
			OpTracker 	tracker

	new make(Str desc) {
		tracker	= OpTracker(desc)
	}
	
	Obj? track(Str description, |->Obj?| operation) {
		tracker.track(description, operation)
	}

	Void log(Str description) {
		tracker.log(description)
	}

	Obj? withModule(Type module, |->Obj?| operation) {
		moduleStack.push(module)
		try {
			// check for recursion
			moduleStack[0..<-1].each { 
				if (it == module)
					throw IocErr(IocMessages.moduleRecursion(moduleStack.map { it.qname }))
			}			
			return operation.call()
		} finally {			
			moduleStack.pop
		}
	}	

	Void withPod(Pod pod, |->Obj?| operation) {
		podStack.push(pod)
		try {
			ignore := false
			
			// check for recursion
			podStack[0..<-1].each { 
				if (it == pod) {
					this.log("Pod '$pod.name' already inspected...ignoring")
					ignore = true
				}
			}
			
			if (!ignore)
				operation.call()
			
		} finally {			
			moduleStack.pop
		}
	}	
}
