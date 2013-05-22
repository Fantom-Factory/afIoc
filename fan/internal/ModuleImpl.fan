
internal const class ModuleImpl : Module {
	
	override const Str				moduleId
	private const ConcurrentState 	conState	:= ConcurrentState(StandardModuleState#)
	private const LocalStash 		stash		:= LocalStash(Module#)
	private const Str:ServiceDef	serviceDefs
	private const Contribution[]	contributions
	private const ObjLocator		objLocator
	
	private Str:Obj perThreadServices {
		get { stash.get("perThreadServices") |->Obj| {[:]} }
		set { }
	}	

	new makeBuiltIn(ObjLocator objLocator, Str moduleId, ServiceDef:Obj? services) {
		serviceDefs	:= Str:ServiceDef[:] 	{ caseInsensitive = true }
	
		services.each |service, def| {
			if (def.scope == ServiceScope.perThread) {
				perThreadServices[def.serviceId] = service
			}
			if (def.scope == ServiceScope.perApplication && service != null) {
				withMyState { 
					it.perApplicationServices[def.serviceId] = service
				}
			}
			withMyState {
				it.stats[def.serviceId] = ServiceStat {
					it.serviceId	= def.serviceId
					it.type			= def.serviceType
					it.scope		= def.scope
					it.lifecycle	= ServiceLifecycle.BUILTIN
					it.noOfImpls	= (service == null) ? 0 : 1
				}
			}
			serviceDefs[def.serviceId] = def
		}
		
		this.moduleId		= moduleId
		this.serviceDefs	= serviceDefs
		this.objLocator 	= objLocator
		this.contributions	= [,]
	}

	new make(ObjLocator objLocator, ModuleDef moduleDef) {
		serviceDefs	:= Str:ServiceDef[:] 	{ caseInsensitive = true }
		
		moduleDef.serviceDefs.each |def| { 
			serviceDefs[def.serviceId] = def
			withMyState {
				it.stats[def.serviceId] = ServiceStat {
					it.serviceId	= def.serviceId
					it.type			= def.serviceType
					it.scope		= def.scope
					it.lifecycle	= ServiceLifecycle.DEFINED
					it.noOfImpls	= 0
				}
			}		
		}
		
		this.moduleId		= moduleDef.moduleId
		this.serviceDefs	= serviceDefs
		this.objLocator 	= objLocator
		this.contributions	= moduleDef.contributionDefs.map |contrib| { 
			ContributionImpl {
				it.serviceId 	= contrib.serviceId
				it.serviceType 	= contrib.serviceType
				it.method		= contrib.method
				it.objLocator 	= objLocator
			}
		}
	}

	// ---- Module Methods ----------------------------------------------------
	
	override ServiceDef? serviceDef(Str serviceId) {
		serviceDefs[serviceId]
	}

    override ServiceDef[] serviceDefsByType(Type serviceType) {
        serviceDefs.findAll |serviceDef, serviceId| {
			serviceType.fits(serviceDef.serviceType)
        }.vals
    }

	override Contribution[] contributionsByServiceDef(ServiceDef serviceDef) {
		contributions.findAll {
			// service def maybe null if contribution is optional
			it.serviceDef?.serviceId == serviceDef.serviceId
		}
	}
	
	override Obj? service(InjectionCtx ctx, Str serviceId) {
        def := serviceDefs[serviceId]
		if (def == null)
			return null

		// we're going deeper!
		return ctx.withServiceDef(def) |->Obj?| {
			if (def.scope == ServiceScope.perInjection) {
				return create(ctx, def)			
			}
			
			if (def.scope == ServiceScope.perThread) {
				return perThreadServices.getOrAdd(def.serviceId) {
					create(ctx, def)
				}
			}
	
//			if (def.scope == ServiceScope.perApplication) {
//				// Because 'Ctx' is created on the call stack and passed from method to method (and 
//				// not held as class state) no other thread can ever access it. Therefore it is  
//				// safe to pass it into my state thread.
//				Unsafe safeCtx := Unsafe(ctx)
//				return getMyState |state -> Obj?| {
//					state.perApplicationServices.getOrAdd(def.serviceId) {
//						create(safeCtx.val, def)
//					}
//				}
//			}
			
			if (def.scope == ServiceScope.perApplication) {
				// I believe there's a slim chance of the service being created twice here, but you'd 
				// need 2 actors requesting the same service at the same time - slim
				// I could make the service here, but I don't want to serialise the ctx
				exists := getMyState |state -> Obj?| { 
					state.perApplicationServices[def.serviceId]
				}
				
				if (exists != null)
					return exists
				
				// keep the tracker in the current thread
				service := create(ctx, def)
				
				withMyState |state| { state.perApplicationServices[def.serviceId] = service }
				return service
			}
			
			throw WtfErr("What scope is {$def.scope}???")
		}
	}
	
	override Str:ServiceStat serviceStats() {
		getMyState { it.stats.toImmutable }
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
	
    private Obj create(InjectionCtx ctx, ServiceDef def) {
		ctx.track("Creating Service '$def.serviceId'") |->Obj| {
	        creator := def.createServiceBuilder
	        service := creator.call(ctx)
			
			withMyState {
				stat := it.stats[def.serviceId]
				it.stats[def.serviceId] = stat.withLifecyle(ServiceLifecycle.CREATED).withNoOfImpls(stat.noOfImpls + 1)
			}
			
			return service				
	    }	
    }
}

internal class StandardModuleState {
	Str:Obj	perApplicationServices	:= Str:Obj[:] 			{ caseInsensitive = true }
	Str:ServiceStat stats			:= Str:ServiceStat[:]	{ caseInsensitive = true }
}
