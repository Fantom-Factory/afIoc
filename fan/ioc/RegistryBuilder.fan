
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

	** Adds a module to the registry. 
	** Any modules defined with the '@SubModule' facet are also added.
	This addModule(Type moduleType) {
		(RegistryBuilder) Utils.stackTraceFilter |->Obj| {		
			ctx.track("Adding module definition for '$moduleType.qname'") |->Obj| {
				lock.check
				internalAddModule(moduleType)
				return this
			}
		}
	}

	** Adds many modules to the registry
	This addModules(Type[] moduleTypes) {
		(RegistryBuilder) Utils.stackTraceFilter |->Obj| {		
			ctx.track("Adding module definitions for '$moduleTypes'") |->Obj| {
				lock.check
				moduleTypes.each |moduleType| {
					internalAddModule(moduleType)
				}
				return this
			}
		}
	}
	
	** Inspects the [pod's meta-data]`docLang::Pods#meta` for the key 'afIoc.module'. This is then 
	** treated as a CSV list of (qualified) module type names to load.
	** 
	** If 'addDependencies' is 'true' then the pod's dependencies are also inspected for IoC 
	** modules. 
	This addModulesFromPod(Pod pod, Bool addDependencies := true) {
		(RegistryBuilder) Utils.stackTraceFilter |->Obj| {		
			ctx.track("Adding module definitions from pod '$pod.name'") |->Obj| {
				lock.check
				if (!options["suppressLogging"])
					logger.info("Adding module definitions from pod '$pod.name'")
				internalAddModulesFromPod(pod, addDependencies)
				return this
			}
		}
	}


	** Note that this method now adds pod dependencies, and not just transitive dependencies as it
	** used to.
	@NoDoc @Deprecated { msg="Use addModulesFromPod() instead" }
	This addModulesFromDependencies(Pod pod, Bool addDependencies := true) {
		addModulesFromPod(pod, addDependencies)
	}

	** Looks for all index properties of key 'afIoc.module' which defines a qualified name of 
	** a module to load.
	This addModulesFromIndexProperties() {
		(RegistryBuilder) Utils.stackTraceFilter |->Obj| {		
			ctx.track("Adding modules from index properties") |->Obj| {
				lock.check

				if (!options["suppressLogging"])
					logger.info("Adding modules from index properties")

				moduleTypeNames := Env.cur.index(IocConstants.podMetaModuleName)
				addModulesFromTypeNames(moduleTypeNames.join(","))
				
				return this
			}
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

	private Void internalAddModule(Type moduleType) {
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
			moduleDefs.add(moduleDef)
			
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

	private Void internalAddModulesFromPod(Pod pod, Bool addDependencies := true) {
		ctx.withPod(pod) |->| {
			moduleTypeNames := pod.meta[IocConstants.podMetaModuleName]
			addModulesFromTypeNames(moduleTypeNames)

			if (addDependencies) {
				mods := ctx.track("Adding dependencies of '${pod.name}'") |->| {
					pod.depends.each |depend| {
						dependency := Pod.find(depend.name)
						internalAddModulesFromPod(dependency)
					}
				} 
			} else
				ctx.log("Not inspecting dependencies")
		}
	}
	
	private Void addModulesFromTypeNames(Str? moduleTypeNames) {
		if (moduleTypeNames == null) {
			ctx.log("No modules found")
			return
		}
		
		moduleTypeNames.split(',', true).each |moduleTypeName| {
			ctx.track("Found module '${moduleTypeName}'") |->| {
				moduleType := Type.find(moduleTypeName)
				internalAddModule(moduleType)
			}
		}		
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
