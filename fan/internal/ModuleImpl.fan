
internal class ModuleImpl : Module {
	
	private Str:ServiceDef	serviceDefs	:= Str:ServiceDef[:] 	{ caseInsensitive = true }
	private Str:Obj			services	:= Str:Obj[:] 			{ caseInsensitive = true }
	private RegistryImpl 	regImpl
	
	new make(RegistryImpl regImpl, ModuleDef moduleDef, Log log) {
		this.regImpl = regImpl
		moduleDef.serviceDefs.each |def| { 
			serviceDefs[def.serviceId] = def
		}
	}
	
	// ---- Public Methods ----------------------------------------------------
	
	override ServiceDef serviceDef(Str serviceId) {
		serviceDefs[serviceId]
	}

    override Str[] findServiceIdsForType(Type serviceType) {
        serviceDefs.findAll |serviceDef, serviceId| {
			serviceDef.serviceType.fits(serviceType)
        }.keys
    }

	override Obj service(Str serviceId) {
        def 	:= serviceDefs[serviceId]
        service := findOrCreate(def)
        return service
	}

	// ---- Private Methods ----------------------------------------------------

	private Obj findOrCreate(ServiceDef def) {
		services.getOrAdd(def.serviceId) {
			create(def)
		}
    }

    private Obj create(ServiceDef def) {
        creator := def.createServiceBuilder
        service := creator.call(regImpl)
		return service
    }	

}
