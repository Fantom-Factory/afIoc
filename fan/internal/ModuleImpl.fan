
internal class ModuleImpl : Module {
	
	private Str:ServiceDef	serviceDefs	:= Str:ServiceDef[:] 	{ caseInsensitive = true }
	
	** Keyed on fully qualified service id; values are instantiated services (proxies).
	private Str:Obj			services	:= Str:Obj[:] 			{ caseInsensitive = true }
	
	private RegistryImpl 	regImpl
	
	new make(RegistryImpl regImpl, ModuleDef moduleDef, Log log) {
		this.regImpl = regImpl
		moduleDef.serviceDefs.each |def| { 
			serviceDefs[def.serviceId] = def
		}
	}
	
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

	private Obj findOrCreate(ServiceDef def) {
		services.getOrAdd(def.serviceId) {
			create(def)
		}
    }

    private Obj create(ServiceDef def) {
//        serviceId 	:= def.serviceId
//        serviceType := def.serviceType
//        logger 		:= registry.getServiceLogger(serviceId)
//        description := "Creating " + (serviceType.isMixin ? "proxy for" : "non-proxied instance of") + " service ${serviceId}"
//        logger.debug(description);

        creator := def.createServiceBuilder
        service := creator.call
		InternalUtils.injectIntoFields(service, regImpl)
		return service
    }	

}
