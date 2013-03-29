
internal class BuiltInModule : Module {
	
	Str:ServiceDef	serviceDefs	:= Str:ServiceDef[:] 	{ caseInsensitive = true }
	Str:Obj			services	:= Str:Obj[:] 			{ caseInsensitive = true }
	
	Void addBuiltInService(Str serviceId, Type serviceType, Obj service) {
		serviceDefs[serviceId] = BuiltInServiceDef() {
			it.serviceId = serviceId
			it.serviceType = serviceType
		}
		services[serviceId] = service
	}
	
	// ---- Module Methods ----------------------------------------------------
	
	override ServiceDef? serviceDef(Str serviceId) {
		serviceDefs[serviceId]
	}

	override Obj? service(OpTracker tracker, Str serviceId) {
        return services[serviceId]
	}

    override Str[] findServiceIdsForType(Type serviceType) {
        serviceDefs.findAll |serviceDef, serviceId| {
			serviceDef.serviceType.fits(serviceType)
        }.keys
    }
}
