
** Builds a `Registry` from Modules. Modules may be added manually, defined by 
** [meta-data]`sys::Pod.meta` in dependent pods or defined by [index properties]`docLang::Env#index`
class RegistryBuilder {
	private const static Log 	logger 		:= Utils.getLog(RegistryBuilder#)
	
	private BuildCtx	ctx 		:= BuildCtx("Building IoC Registry")
	private OneShotLock lock		:= OneShotLock(IocMessages.registryBuilt)
	private ModuleDef[]	moduleDefs	:= [,]

	new make() {
		addModule(IocModule#)
	}

	** Adds a module to the registry
	This addModule(Type moduleType) {
		ctx.track("Adding module definition for '$moduleType.qname'") |->| {
			lock.check
			logger.info("Adding module definition for $moduleType.qname")
			
			ctx.withModule(moduleType) |->| {			
				if (moduleDefs.find { it.moduleType == moduleType } != null) {
					logger.warn(IocMessages.moduleAlreadyAdded(moduleType))
					return
				}
				
				moduleDef := ModuleDefImpl(ctx.tracker, moduleType)
				addModuleDef(moduleDef)
				
				if (moduleType.hasFacet(SubModule#)) {
					subModule := Utils.getFacetOnType(moduleType, SubModule#) as SubModule
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

	** Adds many modules to the registry
	This addModules(Type[] moduleTypes) {
		lock.check
		moduleTypes.each |moduleType| {
			addModule(moduleType)
		}
		return this
	}

	** Checks all dependencies of the given [pod]`sys::Pod` for the meta-data key 'afIoc.module' 
	** which defines the qualified name of a module to load.
	This addModulesFromDependencies(Pod pod, Bool addTransitiveDependencies := true) {
		logger.info("Adding modules from dependencies of '$pod.name'")
		addModulesFromDependenciesRecursive(pod, addTransitiveDependencies)
		return this
	}

	** Looks for all index properties of the key 'afIoc.module' which defines a qualified name of 
	** a module to load.
	This addModulesFromIndexProperties() {
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
	
	** Constructs and returns the registry; this may only be done once. The caller is responsible for invoking
	** `Registry.startup`
    Registry build() {
		lock.lock
        registry := RegistryImpl(ctx.tracker, moduleDefs)
		ctx.tracker.end
		return registry
    }
	
	// ---- Private Methods -----------------------------------------------------------------------

	private Type[] addModulesFromDependenciesRecursive(Pod pod, Bool addTransitiveDependencies) {
		ctx.track("Adding modules from dependencies of '$pod.name'") |->Type[]| {
			lock.check
			
			Type?[] modTypes := [,]
			
			// don't forget me!
			modType := addModuleFromPod(pod)
			modTypes.add(modType)
			
			pod.depends.each {
				dependency := Pod.find(it.name)
				mod := addModuleFromPod(dependency)
				modTypes.add(mod)
				
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
			
			modTypes = modTypes.exclude { it == null }
			if (modTypes.isEmpty)
				ctx.log("No modules found")
			
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
			return operation()
		} finally {			
			moduleStack.pop
		}
	}	
}
