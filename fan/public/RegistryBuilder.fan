
** Use to create an IoC `Registry`. Modules may be added manually, defined by 
** [meta-data]`sys::Pod.meta` in dependent pods or defined by [index properties]`docLang::Env#index`
class RegistryBuilder {
	private const static Log	logger	:= Utils.getLog(RegistryBuilder#)
	
	private BuildCtx	ctx 		:= BuildCtx("Building IoC Registry")
	private OneShotLock lock		:= OneShotLock(IocMessages.registryBuilt)
	private ModuleDef[]	moduleDefs	:= [,]

	** Use options to pass state into the IoC Registry. 
	** This map may be later retrieved from the `RegistryMeta` service. 
	Str:Obj?	options {
		private set
	}
	
	** Set to 'true' to suppress builder logging.
	@NoDoc Bool suppressLogging	:= false

	@NoDoc 
	new make() {
		options	= Utils.makeMap(Str#, Obj?#)
		addModule(IocModule#)
	}

	** Adds a module to the registry. 
	** Any modules defined with the '@SubModule' facet are also added.
	This addModule(Type moduleType) {
		(RegistryBuilder) Utils.stackTraceFilter |->Obj| {		
			ctx.track("Adding module definition for '$moduleType.qname'") |->Obj| {
				lock.check
				_addModule(moduleType)
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
					_addModule(moduleType)
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
				if (!suppressLogging)
					logger.info("Adding module definitions from pod '$pod.name'")
				_addModulesFromPod(pod, addDependencies)
				return this
			}
		}
	}

	** Looks for all index properties of key 'afIoc.module' which defines a qualified name of 
	** a module to load.
	This addModulesFromIndexProperties() {
		(RegistryBuilder) Utils.stackTraceFilter |->Obj| {		
			ctx.track("Adding modules from index properties") |->Obj| {
				lock.check

				if (!suppressLogging)
					logger.info("Adding modules from index properties")

				moduleTypeNames := Env.cur.index(IocConstants.podMetaModuleName)
				_addModulesFromTypeNames(moduleTypeNames.join(","))
				
				return this
			}
		}
	}

	** Removes the given module type from this builder. 
	** Handy if an un-wanted transitive dependency is added unwittingly.
	** 
	** Returns 'true' if the given module was removed.
	Bool removeModule(Type moduleType) {
		doomed := moduleDefs.find { it.moduleType == moduleType }
		moduleDefs.remove(doomed)
		return doomed != null
	}

	** Returns a list of modules types currently held by this builder.
	Type[] moduleTypes() {
		moduleDefs.map { it.moduleType }
	}
	
	** Returns a value from the 'options' map.
	@Operator
	Obj? get(Str name) {
		options[name]
	}

	** Sets a value in the 'options' map. 
	** Returns 'this' so it may be used as a builder method.. 
	@Operator
	This set(Str name, Obj? value) {
		options[name] = value
		return this
	}
	
	** Constructs and returns the registry; this may only be done once. The caller is responsible 
	** for invoking `Registry.startup`.
    Registry build() {
		Utils.stackTraceFilter |->Obj| {
			lock.lock
	
			defaults := Utils.makeMap(Str#, Obj#).addAll([
				"afIoc.bannerText" : "Alien-Factory IoC v$typeof.pod.version",
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

	private Void _addModule(Type moduleType) {
		if (moduleType != IocModule# && !suppressLogging && !moduleTypes.contains(moduleType))
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

	private Void _addModulesFromPod(Pod pod, Bool addDependencies := true) {
		ctx.withPod(pod) |->| {
			moduleTypeNames := pod.meta[IocConstants.podMetaModuleName]
			_addModulesFromTypeNames(moduleTypeNames)

			if (addDependencies) {
				mods := ctx.track("Adding dependencies of '${pod.name}'") |->| {
					pod.depends.each |depend| {
						dependency := Pod.find(depend.name)
						_addModulesFromPod(dependency)
					}
				} 
			} else
				ctx.log("Not inspecting dependencies")
		}
	}
	
	private Void _addModulesFromTypeNames(Str? moduleTypeNames) {
		if (moduleTypeNames == null) {
			ctx.log("No modules found")
			return
		}
		
		moduleTypeNames.split(',', true).each |moduleTypeName| {
			ctx.track("Found module '${moduleTypeName}'") |->| {
				moduleType := Type.find(moduleTypeName)
				_addModule(moduleType)
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
		if (moduleStack.contains(module))
			throw IocErr(IocMessages.moduleRecursion(moduleStack.dup.add(module)))

		moduleStack.push(module)
		try {
			return operation.call
		} finally {			
			moduleStack.pop
		}
	}	

	Void withPod(Pod pod, |->Obj?| operation) {
		if (podStack.contains(pod)) {
			this.log("Pod '$pod.name' already inspected...ignoring")
			return
		}
		
		podStack.push(pod)
		try {
			operation.call
		} finally {			
			podStack.pop
		}
	}	
}
