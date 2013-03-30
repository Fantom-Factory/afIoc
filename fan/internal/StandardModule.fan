
internal class StandardModule : Module {
	
	private Str:ServiceDef	serviceDefs	:= Str:ServiceDef[:] 	{ caseInsensitive = true }
	private Str:Obj			services	:= Str:Obj[:] 			{ caseInsensitive = true }
	private ObjLocator		objLocator
	
	new make(ObjLocator objLocator, ModuleDef moduleDef) {
		this.objLocator = objLocator
		moduleDef.serviceDefs.each |def| { 
			serviceDefs[def.serviceId] = def
		}
	}

	// ---- Module Methods ----------------------------------------------------
	
	override ServiceDef? serviceDef(Str serviceId) {
		serviceDefs[serviceId]
	}

	override Obj? service(OpTracker tracker, Str serviceId) {
        def := serviceDefs[serviceId]
		if (def == null)
			return null
		return services.getOrAdd(def.serviceId) {
			tracker.track("Creating Service '$def.serviceId'") |->Obj| {
				create(tracker, def)
			}
		}
	}

    override Str[] findServiceIdsForType(Type serviceType) {
        serviceDefs.findAll |serviceDef, serviceId| {
			serviceDef.serviceType.fits(serviceType)
        }.keys
    }

	// ---- Private Methods ----------------------------------------------------

    private Obj create(OpTracker tracker, ServiceDef def) {
        creator := def.createServiceBuilder
        service := creator.call(tracker, objLocator)
		return service
    }	

}
