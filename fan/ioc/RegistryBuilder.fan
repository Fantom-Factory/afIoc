
class RegistryBuilder {
	private OneShotLock lock		:= OneShotLock()
	private ModuleDef[]	moduleDefs	:= [,]
	
	This addTypes(Type[] moduleTypes) {
		lock.check		
		moduleTypes.each |moduleType| {
			addType(moduleType)
		}
		return this
	}

	This addType(Type moduleType) {
		lock.check

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
