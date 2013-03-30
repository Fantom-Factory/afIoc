
internal class BuiltInModule : Module {
	
	Str:ServiceDef	serviceDefs	:= Str:ServiceDef[:] 	{ caseInsensitive = true }
	private Str:Obj			services	:= Str:Obj[:] 			{ caseInsensitive = true }
	private ObjLocator		objLocator
	
	new make(ObjLocator objLocator) {
		this.objLocator = objLocator
	}
	
	Void addBuiltInService(Str serviceId, Type serviceType, Obj service) {
		serviceDefs[serviceId] = BuiltInServiceDef() {
			it.serviceId = serviceId
			it.serviceType = serviceType
			it.scope = ScopeDef.perApplication
		}
		services[serviceId] = service
	}

	Void addBuiltInServiceDef(ServiceDef serviceDef) {
		serviceDefs[serviceDef.serviceId] = serviceDef
	}
	
	// ---- Module Methods ------------------------------------------------------------------------
	
	override ServiceDef? serviceDef(Str serviceId) {
		serviceDefs[serviceId]
	}

	override Obj? service(OpTracker tracker, Str serviceId) {
        service := services[serviceId]
		if (service != null)
			return service
		
		// special case for ctorFieldInjector - autobuild each time so we can pass in the tracker
		// should be extracted to some notion of Scope 
		if (serviceDefs.containsKey(serviceId))
			return serviceDefs[serviceId].createServiceBuilder.call(tracker, objLocator)
		
		return null
	}

    override Str[] findServiceIdsForType(Type serviceType) {
        serviceDefs.findAll |serviceDef, serviceId| {
			serviceDef.serviceType.fits(serviceType)
        }.keys
    }
}
