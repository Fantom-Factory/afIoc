
internal const class ModuleImpl : Module {
	
	override const Str				moduleId
	private const ConcurrentState 	conState	:= ConcurrentState(StandardModuleState#)
	private const LocalStash 		stash		:= LocalStash(typeof)
	private const Str:ServiceDef	serviceDefs
	private const ObjLocator		objLocator
	
	private Str:Obj perThreadServices {
		get { stash.get("perThreadServices") |->Obj| {[:]} }
		set { }
	}	

	new makeBuiltIn(ObjLocator objLocator, Str moduleId, ServiceDef:Obj? services) {
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
		
		this.moduleId		= moduleId
		this.serviceDefs	= serviceDefs
		this.objLocator 	= objLocator
	}

	new make(ObjLocator objLocator, ModuleDef moduleDef) {
		serviceDefs	:= Str:ServiceDef[:] 	{ caseInsensitive = true }
		
		moduleDef.serviceDefs.each |def| { 
			serviceDefs[def.serviceId] = def
		}
		
		this.moduleId		= moduleDef.moduleId
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

			// I believe there's a slim chance of the service being created twice here, but you'd 
			// need 2 actors requesting the same service at the same time 
			exists := getMyState |state -> Obj?| { 
				state.perApplicationServices[def.serviceId]
			}
			
			if (exists != null)
				return exists
			
			// keep the tracker in the current thread
			service := create(tracker, def)
			
			withMyState |state| { state.perApplicationServices[def.serviceId] = service }
			return service
		}

		throw WtfErr("What scope is {$def.scope}???")
	}

    override ServiceDef[] serviceDefsByType(Type serviceType) {
        serviceDefs.findAll |serviceDef, serviceId| {
			serviceDef.serviceType.fits(serviceType)
        }.vals
    }
	
	override Void clear() {
		perThreadServices.clear
		withMyState { 
			it.perApplicationServices.clear
		}
	}

	// ---- Private Methods ----------------------------------------------------

	private Void withMyState(|StandardModuleState| state) {
		conState.withState(state)
	}

	private Obj? getMyState(|StandardModuleState -> Obj| state) {
		conState.getState(state)
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
