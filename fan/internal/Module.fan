
internal class Module {
	
	private Str:ServiceDef	serviceDefs	:= Str:ServiceDef[:] 	{ caseInsensitive = true }
	private Str:Obj			services	:= Str:Obj[:] 			{ caseInsensitive = true }
	private ObjLocator		objLocator
	
	new make(ObjLocator objLocator, ModuleDef moduleDef, Log log) {
		this.objLocator = objLocator
		moduleDef.serviceDefs.each |def| { 
			serviceDefs[def.serviceId] = def
		}
	}
	
	// ---- Public Methods ----------------------------------------------------
	
	** Returns the service definition for the given service id
	ServiceDef serviceDef(Str serviceId) {
		serviceDefs[serviceId]
	}

	** Locates the ids of all services that implement the provided service type, or whose service type is
    ** assignable to the provided service type (is a super-class or super-mixin).
    Str[] findServiceIdsForType(Type serviceType) {
        serviceDefs.findAll |serviceDef, serviceId| {
			serviceDef.serviceType.fits(serviceType)
        }.keys
    }

	** Locates (and builds if necessary) a service given a service id
	Obj service(OpTracker tracker, Str serviceId) {
        def 	:= serviceDefs[serviceId]
        service := findOrCreate(tracker, def)
        return service
	}

	// ---- Private Methods ----------------------------------------------------

	private Obj findOrCreate(OpTracker tracker, ServiceDef def) {
		services.getOrAdd(def.serviceId) {
			tracker.track("Creating Service '$def.serviceId'") |->Obj| {
				create(tracker, def)
			}
		}
    }

    private Obj create(OpTracker tracker, ServiceDef def) {
        creator := def.createServiceBuilder
        service := creator.call(tracker, objLocator)
		return service
    }	

}
