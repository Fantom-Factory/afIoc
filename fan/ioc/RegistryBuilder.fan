
class RegistryBuilder {
	private const static Log 	log 		:= Log.get(RegistryBuilder#.name)
	
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
	
	** Constructs and returns the registry; this may only be done once. The caller is responsible for invoking
	** `Registry#performRegistryStartup()`
    Registry build() {
		lock.lock
		
        return RegistryImpl(moduleDefs)
    }
	
	private This addModuleDef(ModuleDef moduleDef) {
		lock.check

		this.moduleDefs.add(moduleDef)
		return this
	}
}
