
** Builds a `Registry` from Modules. Modules may be added manually, defined by 
** [meta-data]`sys::Pod.meta` in dependent pods or defined by [index properties]`docLang::Env#index`
class RegistryBuilder {
	private const static Log 	logger 		:= Utils.getLog(RegistryBuilder#)
	
	private OpTracker	tracker 	:= OpTracker("Building IoC Registry")
	private OneShotLock lock		:= OneShotLock(IocMessages.registryBuilt)
	private ModuleDef[]	moduleDefs	:= [,]

	new make() {
		addModule(IocModule#)
	}

	** Adds a module to the registry
	This addModule(Type moduleType) {
		// FIXME: prevent module recursion
		// FIXME: prevent the same module from being loaded twice
		tracker.track("Adding module definition for '$moduleType.qname'") |->| {
			lock.check
			logger.info("Adding module definition for $moduleType.qname")
			
			moduleDef := ModuleDefImpl(tracker, moduleType)
			addModuleDef(moduleDef)
			
			if (moduleType.hasFacet(SubModule#)) {
				subModule := Utils.getFacetOnType(moduleType, SubModule#) as SubModule
				tracker.track("Found SubModule facet on $moduleType.qname : $subModule.modules") |->| {
					subModule.modules.each { 
						addModule(it)
					}
				}
			} else
				tracker.log("No SubModules found")
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
		tracker.track("Adding modules from index properties") |->| {
			lock.check
			moduleNames := Env.cur.index("afIoc.module")
			moduleNames.each {
				addModuleFromTypeName(tracker, it)
			}
			if (moduleNames.isEmpty)
				tracker.log("No modules found")
		}
		return this
	}
	
	** Constructs and returns the registry; this may only be done once. The caller is responsible for invoking
	** `Registry.startup`
    Registry build() {
		lock.lock
        registry := RegistryImpl(tracker, moduleDefs)
		tracker.end
		return registry
    }
	
	// ---- Private Methods -----------------------------------------------------------------------
	
	private Type[] addModulesFromDependenciesRecursive(Pod pod, Bool addTransitiveDependencies) {
		tracker.track("Adding modules from dependencies of '$pod.name'") |->Type[]| {
			lock.check
			
			Type?[] modTypes := [,]
			
			// don't forget me!
			modType := addModuleFromPod(tracker, pod)
			modTypes.add(modType)
			
			pod.depends.each {
				dependency := Pod.find(it.name)
				mod := addModuleFromPod(tracker, dependency)
				modTypes.add(mod)
				
				if (addTransitiveDependencies) {
					mods := tracker.track("Adding transitive dependencies for '$dependency.name'") |->Obj| {
						deps := addModulesFromDependenciesRecursive(dependency, addTransitiveDependencies)
						if (deps.isEmpty)
							tracker.log("No transitive dependencies found")
						return deps
					} 
					modTypes.addAll(mods)
				} else
					tracker.log("Not looking for transitive dependencies")
			}
			
			modTypes = modTypes.exclude { it == null }
			if (modTypes.isEmpty)
				tracker.log("No modules found")
			
			return modTypes
		}
	}	
	
	private Type? addModuleFromPod(OpTracker tracker, Pod pod) {
		qname := pod.meta[IocConstants.podMetaModuleName]
		if (qname != null) {
			tracker.log("Pod '$pod.name' defines module of type $qname")
			return addModuleFromTypeName(tracker, qname)
		}
		return null
	}

	private Type addModuleFromTypeName(OpTracker tracker, Str moduleTypeName) {
		moduleType := Type.find(moduleTypeName)
		addModule(moduleType)
		return moduleType
	}

	private This addModuleDef(ModuleDef moduleDef) {
		this.moduleDefs.add(moduleDef)
		return this
	}
}
