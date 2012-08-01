
class RegistryBuilder {
	private OneShotLock lock		:= OneShotLock()
	private ModuleDef[]	moduleDefs	:= [,]
	
	This addModuleDef(ModuleDef moduleDef) {
		lock.check

		this.moduleDefs.add(moduleDef)
		return this
	}
	
	This addTypes(Type[] moduleTypes) {
		lock.check
		
		moduleTypes.each |moduleType| {
			moduleDef := ModuleDefImpl(moduleType)
            addModuleDef(moduleDef)
			// TODO: Check for @SubModule facets
		}
		return this
	}
	
	** Constructs and returns the registry; this may only be done once. The caller is responsible for invoking
	** `Registry#performRegistryStartup()`
	**// FIMXE: null
    public Registry? build() {
		lock.lock

		return null
		// FIXME:
//        return RegistryImpl(moduleDefs)
    }
	
}
