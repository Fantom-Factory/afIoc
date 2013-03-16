
internal class ModuleImpl : Module {
	
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
	
	override ServiceDef serviceDef(Str serviceId) {
		serviceDefs[serviceId]
	}

    override Str[] findServiceIdsForType(Type serviceType) {
        serviceDefs.findAll |serviceDef, serviceId| {
			serviceDef.serviceType.fits(serviceType)
        }.keys
    }

	override Obj service(OpTracker tracker, Str serviceId) {
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
