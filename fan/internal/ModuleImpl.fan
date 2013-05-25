
internal const class ModuleImpl : Module {
	
	override const Str				moduleId
	private const ConcurrentState 	conState	:= ConcurrentState(StandardModuleState#)
	private const ThreadStash 		stash
	private const Str:ServiceDef	serviceDefs
	private const Contribution[]	contributions
	private const AdviceDef[]		adviceDefs
	private const ObjLocator		objLocator

	private Str:Obj perThreadServices {
		get { stash.get("perThreadServices") |->Obj| {[:]} }
		set { }
	}	

	new makeBuiltIn(ObjLocator objLocator, ThreadStashManager stashManager, Str moduleId, ServiceDef:Obj? services) {
		stash = stashManager.createStash(ServiceIds.builtInModuleId)
		serviceDefs	:= Str:ServiceDef[:] { caseInsensitive = true }
	
		services.each |service, def| {
			if (def.scope == ServiceScope.perThread) {
				if (service != null)
					perThreadServices[def.serviceId] = service
			}
			if (def.scope == ServiceScope.perApplication) {
				if (service != null)
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
		this.adviceDefs		= [,]
	}

	new make(ObjLocator objLocator, ThreadStashManager stashManager, ModuleDef moduleDef) {
		stash = stashManager.createStash(moduleDef.moduleId)
		serviceDefs	:= Str:ServiceDef[:] { caseInsensitive = true }
		
		moduleDef.serviceDefs.each |def| { 
			serviceDefs[def.serviceId] = def
			withMyState {
				it.stats[def.serviceId] = ServiceStat {
					it.serviceId	= def.serviceId
					it.type			= def.serviceType
					it.scope		= def.scope
					it.proxyDisabled= def.noProxy
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
		this.adviceDefs		= moduleDef.adviceDefs
	}

	// ---- Module Methods ----------------------------------------------------
	
	override ServiceDef? serviceDef(Str serviceId) {
		serviceDefs[serviceId]
	}

    override ServiceDef[] serviceDefsByType(Type serviceType) {
		// TODO: use a cached adapter pattern
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
	
	override AdviceDef[] adviceByServiceDef(ServiceDef serviceDef) {
		adviceDefs.findAll {
			it.matchesServiceId(serviceDef.serviceId)
		}
	}
	
	override Obj? service(InjectionCtx ctx, Str serviceId, Bool forceCreate) {
        def := serviceDefs[serviceId]
		if (def == null)
			// nope, the service is not one of ours
			return null

		// we're going deeper!
		return ctx.withServiceDef(def) |->Obj?| {
			
			if (def.scope == ServiceScope.perInjection) {
				return create(ctx, def, forceCreate)
			}
			
			if (def.scope == ServiceScope.perThread) {
				service := perThreadServices.getOrAdd(serviceId) {
					create(ctx, def, forceCreate)
				}
				
				// if asked, replace the cached VIRTUAL service with a real one
				status := (ServiceStat) getMyState { it.stats[serviceId] }
				if (forceCreate && status.lifecycle == ServiceLifecycle.VIRTUAL) {
					service = create(ctx, def, forceCreate)
					perThreadServices[serviceId] = service
				}
				
				return service
			}

			if (def.scope == ServiceScope.perApplication) {
				
				// Because of recursion (service1 creates service2), you can not create the service
				// inside an actor ('cos the actor will block when it eventually messages itself). 
				// So...
				// TODO: A const service could be created twice if there's a race condition between
				// two threads. And who knows what those services do in their ctor or PostInject 
				// methods!
				exists := getMyState |state -> Obj?| { 
					state.perApplicationServices[def.serviceId]
				}
				
				// if asked, replace the cached VIRTUAL service with a real one
				status 		:= (ServiceStat) getMyState { it.stats[serviceId] }
				make4Real	:= forceCreate && status.lifecycle == ServiceLifecycle.VIRTUAL
				
				if (!make4Real && exists != null)
					return exists
				
				// keep the tracker in the current thread
				service := create(ctx, def, forceCreate)

				// in a race condition, the 2nd service created wins
				withMyState |state -> Obj| {
					// double check service existence
					state.perApplicationServices.getOrAdd(def.serviceId) {
						service
					}
				}
				
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
	
    private Obj create(InjectionCtx ctx, ServiceDef def, Bool forceCreate) {
		status := (ServiceStat) getMyState { it.stats[def.serviceId] }

		if (ctx.objLocator.options["disableProxies"] == true)
			forceCreate = true
		
		if (!forceCreate && def.proxiable && status.lifecycle == ServiceLifecycle.DEFINED) {
			return ctx.track("Creating VIRTUAL Service '$def.serviceId'") |->Obj| {
				proxyBuilder 	:= (ServiceProxyBuilder) objLocator.trackServiceById(ctx, ServiceIds.serviceProxyBuilder)
				service			:= proxyBuilder.buildProxy(ctx.tracker, def)
				
				withMyState {
					stat := it.stats[def.serviceId]
					it.stats[def.serviceId] = stat.withLifecyle(ServiceLifecycle.VIRTUAL)
				}
				
				return service
			}
		}
		
		return ctx.track("Creating REAL Service '$def.serviceId'") |->Obj| {
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
