
** Use to create an IoC `Registry`. Modules may be added manually, defined by 
** [meta-data]`sys::Pod.meta` in dependent pods or defined by [index properties]`docLang::Env#index`
@Serializable
class RegistryBuilder {
	private const static Log	logger	:= Utils.getLog(RegistryBuilder#)
	
	@Transient
	private BuildCtx	_ctx 			:= BuildCtx("Building IoC Registry")
	@Transient
	private OneShotLock _lock			:= OneShotLock(IocMessages.registryBuilt)

	private Type[]		_moduleTypes	:= [,]

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
	}

	** Adds a module to the registry. 
	** Any modules defined with the '@SubModule' facet are also added.
	This addModule(Type moduleType) {
		(RegistryBuilder) Utils.stackTraceFilter |->Obj| {		
			_ctx.track("Adding module definition for '$moduleType.qname'") |->Obj| {
				_lock.check
				_addModule(moduleType)
				return this
			}
		}
	}

	** Adds many modules to the registry
	This addModules(Type[] moduleTypes) {
		(RegistryBuilder) Utils.stackTraceFilter |->Obj| {		
			_ctx.track("Adding module definitions for '$moduleTypes'") |->Obj| {
				_lock.check
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
	This addModulesFromPod(Str podName, Bool addDependencies := true) {
		pod := Pod.find(podName)
		return (RegistryBuilder) Utils.stackTraceFilter |->Obj| {		
			_ctx.track("Adding module definitions from pod '$pod.name'") |->Obj| {
				_lock.check
				if (!suppressLogging)
					logger.info("Adding module definitions from pod '$pod.name'")
				_addModulesFromPod(pod, addDependencies)
				return this
			}
		}
	}

	** Looks for all index properties of key 'afIoc.module' which defines a qualified name of 
	** a module to load.
	This addModulesFromIndexProps() {
		(RegistryBuilder) Utils.stackTraceFilter |->Obj| {		
			_ctx.track("Adding modules from index properties") |->Obj| {
				_lock.check

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
		_moduleTypes.remove(moduleType) != null
	}

	** Returns the list of modules types currently held by this builder.
	Type[] moduleTypes() {
		_moduleTypes
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
	
	** Returns a copy of this 'RegistryBuilder'. 
	This dup() {
		RegistryBuilder() {
			it.options = this.options.dup
			it._moduleTypes = this._moduleTypes.dup
			it.suppressLogging = this.suppressLogging
		}
	}
	
	** Constructs and returns the registry; this may only be done once. The caller is responsible 
	** for invoking `Registry.startup`.
    Registry build() {
		Utils.stackTraceFilter |->Obj| {
			_lock.lock
	
			defaults := Utils.makeMap(Str#, Obj#).addAll([
				"afIoc.bannerText" : "Alien-Factory IoC v$typeof.pod.version",
			])

			defaults.each |val, key| {
				optType := options[key]?.typeof
				if (optType != null && optType != val.typeof)
					throw IocErr(IocMessages.invalidRegistryValue(key, optType, val.typeof))
			}

			moduleDefs := _moduleTypes.map {
				ModuleDef(_ctx.tracker, it)
			}
			
	        registry := RegistryImpl(_ctx.tracker, moduleDefs, defaults.setAll(options))
			_ctx.tracker.end
			return registry
		}
    }
	
	// ---- Private Methods -----------------------------------------------------------------------

	private Void _addModule(Type moduleType) {
		if (!suppressLogging && !moduleTypes.contains(moduleType))
			logger.info("Adding module definition for $moduleType.qname")

		_ctx.withModule(moduleType) |->| {			
			if (_moduleTypes.contains(moduleType)) {
				// Debug because sometimes you can't help adding the same module twice (via dependencies)
				// afBedSheet is a prime example
				logger.debug(IocMessages.regBuilder_moduleAlreadyAdded(moduleType))
				return
			}

			_moduleTypes.add(moduleType)
			
			if (moduleType.hasFacet(SubModule#)) {
				subModule := (SubModule) Type#.method("facet").callOn(moduleType, [SubModule#])	// Stoopid F4
				_ctx.track("Found SubModule facet on $moduleType.qname : $subModule.modules") |->| {
					subModule.modules.each { 
						addModule(it)
					}
				}
			} else
				_ctx.log("No SubModules found")
		}
	}

	private Void _addModulesFromPod(Pod pod, Bool addDependencies := true) {
		_ctx.withPod(pod) |->| {
			moduleTypeNames := pod.meta[IocConstants.podMetaModuleName]
			_addModulesFromTypeNames(moduleTypeNames)

			if (addDependencies) {
				_ctx.track("Adding dependencies of '${pod.name}'") |->| {
					pod.depends.each |depend| {
						dependency := Pod.find(depend.name)
						_addModulesFromPod(dependency)
					}
				} 
			} else
				_ctx.log("Not inspecting dependencies")
		}
	}
	
	private Void _addModulesFromTypeNames(Str? moduleTypeNames) {
		if (moduleTypeNames == null) {
			_ctx.log("No modules found")
			return
		}
		
		moduleTypeNames.split(',', true).each |moduleTypeName| {
			_ctx.track("Found module '${moduleTypeName}'") |->| {
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
			throw IocErr(IocMessages.regBuilder_moduleRecursion(moduleStack.dup.add(module)))

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
