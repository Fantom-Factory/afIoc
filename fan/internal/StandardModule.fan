
internal const class StandardModule : ConcurrentState, Module {
	
	private const LocalStash 		stash	:= LocalStash(typeof)
	private const Str:ServiceDef	serviceDefs
	private const ObjLocator		objLocator
	
	private Str:Obj perThreadServices {
		get { stash.get("perThreadServices") |->Obj| {[:]} }
		set { }
	}	

	new makeBuiltIn(ObjLocator objLocator, ServiceDef:Obj? services) : super.make(StandardModuleState#) {
		serviceDefs	:= Str:ServiceDef[:] 	{ caseInsensitive = true }
	
		services.each |service, def| {
			if (def.scope == ScopeDef.perThread) {
				perThreadServices[def.serviceId] = service
			}
			if (def.scope == ScopeDef.perApplication) {
				withMyState { 
					it.perApplicationServices[def.serviceId] = service
				}
			}
			serviceDefs[def.serviceId] = def
		}
		
		this.serviceDefs	= serviceDefs
		this.objLocator 	= objLocator
	}

	new make(ObjLocator objLocator, ModuleDef moduleDef) : super(StandardModuleState#) {
		serviceDefs	:= Str:ServiceDef[:] 	{ caseInsensitive = true }
		
		moduleDef.serviceDefs.each |def| { 
			serviceDefs[def.serviceId] = def
		}
		
		this.serviceDefs	= serviceDefs
		this.objLocator 	= objLocator
	}

	// ---- Module Methods ----------------------------------------------------
	
	override ServiceDef? serviceDef(Str serviceId) {
		serviceDefs[serviceId]
	}

	override Obj? service(OpTracker tracker, Str serviceId) {
        def := serviceDefs[serviceId]
		if (def == null)
			return null

		if (def.scope == ScopeDef.perInjection) {
			return create(tracker, def)			
		}
		
		if (def.scope == ScopeDef.perThread) {
			return perThreadServices.getOrAdd(def.serviceId) {
				create(tracker, def)
			}
		}

		if (def.scope == ScopeDef.perApplication) {
			// TODO: when tested, try putting all in one closure
			exists := getMyState |state| { 
				state.perApplicationServices.containsKey(def.serviceId) 
			}
			
			if (exists)
				return getMyState |state| { state.perApplicationServices[def.serviceId] }
			
			service := create(tracker, def)
			withMyState |state| { state.perApplicationServices[def.serviceId] = service }
			return service
		}

		throw WtfErr("What scope is {$def.scope}???")
	}

    override Str[] findServiceIdsForType(Type serviceType) {
        serviceDefs.findAll |serviceDef, serviceId| {
			serviceDef.serviceType.fits(serviceType)
        }.keys
    }
	
	override Void clear() {
		perThreadServices.clear
		withMyState { 
			it.perApplicationServices.clear
		}
	}

	// ---- Private Methods ----------------------------------------------------

	private Void withMyState(|StandardModuleState| state) {
		super.withState(state)
	}

	private Obj? getMyState(|StandardModuleState -> Obj| state) {
		super.getState(state)
	}
	
    private Obj create(OpTracker tracker, ServiceDef def) {
		tracker.track("Creating Service '$def.serviceId'") |->Obj| {
	        creator := def.createServiceBuilder
	        service := creator.call(tracker, objLocator)
			return service
	    }	
    }
}

internal class StandardModuleState {
	Str:Obj	perApplicationServices := Str:Obj[:] { caseInsensitive = true }
}
