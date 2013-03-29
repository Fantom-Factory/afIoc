
class RegistryBuilder {
	private const static Log 	log 		:= Utils.getLog(RegistryBuilder#)
	
	private OneShotLock lock		:= OneShotLock()
	private ModuleDef[]	moduleDefs	:= [,]
	
	This addModules(Type[] moduleTypes) {
		lock.check		
		moduleTypes.each |moduleType| {
			addModule(moduleType)
		}
		return this
	}

	This addModule(Type moduleType) {
		lock.check

		log.info("Adding module definition for $moduleType.qname");
		moduleDef := ModuleDefImpl(moduleType)
		addModuleDef(moduleDef)
		// TODO: Check for @SubModule facets
		return this
	}
	
	This addModulesFromDependencies() {
		lock.check
		// TODO: addModulesFromDependencies
//		Pod.find("").depends[0].
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
        return RegistryImpl(moduleDefs)
    }
	
	private This addModuleDef(ModuleDef moduleDef) {
		this.moduleDefs.add(moduleDef)
		return this
	}
}
