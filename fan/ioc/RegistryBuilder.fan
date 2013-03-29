
** Builds a `Registry` from Modules. Modules may be added manually, defined my meta-data in 
** dependent pods or defined by [index properties]`docLang::Env#index`
class RegistryBuilder {
	private const static Log 	log 		:= Utils.getLog(RegistryBuilder#)
	
	private OneShotLock lock		:= OneShotLock()
	private ModuleDef[]	moduleDefs	:= [,]
	
	// FIXME: use tracker!
	private OpTracker	tracker 	:= OpTracker()
	
	** Adds many modules to the registry
	This addModules(Type[] moduleTypes) {
		lock.check		
		moduleTypes.each |moduleType| {
			addModule(moduleType)
		}
		return this
	}

	** Adds a module to the registry
	This addModule(Type moduleType) {
		lock.check

		log.info("Adding module definition for $moduleType.qname");
		moduleDef := ModuleDefImpl(moduleType)
		addModuleDef(moduleDef)
		// TODO: Check for @SubModule facets
		return this
	}
	
	** Adds all modules from all the dependencies of the given pod that are defined by the meta-data
	This addModulesFromDependencies(Pod pod) {
		lock.check
		
		pod.depends
			.map { 
				Pod.find(it.name).meta["afIoc.module"]
			}
			.exclude {
				it == null
			}
			.map {
				Type.find(it)
			}
			.each {
				addModule(it)
			}
		
		return this
	}

	This addModulesFromIndexProperties() {
		lock.check
		moduleNames := Env.cur.index("afIoc.module")
		moduleNames.each |moduleName| {
			addModule(Type.find(moduleName))
		}
		return this
	}
	
	** Constructs and returns the registry; this may only be done once. The caller is responsible for invoking
	** `Registry.startup`
    Registry build() {
		lock.lock
        return RegistryImpl(tracker, moduleDefs)
    }
	
	private This addModuleDef(ModuleDef moduleDef) {
		this.moduleDefs.add(moduleDef)
		return this
	}
}
