
internal const class ModuleImpl : Module {
	
	override const Str				moduleId
	
	private const ConcurrentState 	appServices		:= ConcurrentState(ModuleServices#)
	private const ConcurrentState 	serviceStat		:= ConcurrentState(ModuleStats#)
	
	private const ThreadStash 		threadStash
	private const Str:ServiceDef	serviceDefs
	private const Contribution[]	contributions
	private const AdviceDef[]		adviceDefs
	private const ObjLocator		objLocator
	private const StrategyRegistry	typeToServiceDefs

	private ModuleServices threadServices {
		get { threadStash.get("perThreadState") |->ModuleServices| {ModuleServices()} }
		set { }
	}

	new makeBuiltIn(ObjLocator objLocator, ThreadStashManager stashManager, Str moduleId, ServiceDef:Obj? services) {
		threadStash = stashManager.createStash(ServiceIds.builtInModuleId)
		serviceDefs	:= Str:ServiceDef[:] { caseInsensitive = true }
	
		services.each |service, def| {
			
			if (service != null)
				setService(def, service)

			stat := ServiceStat {
				it.serviceId	= def.serviceId
				it.type			= def.serviceType
				it.scope		= def.scope
				it.lifecycle	= ServiceLifecycle.BUILTIN
				it.noOfImpls	= (service == null) ? 0 : 1
			}
			
			setStat(def, stat)

			serviceDefs[def.serviceId] = def
		}
		
		this.moduleId		= moduleId
		this.serviceDefs	= serviceDefs
		this.objLocator 	= objLocator
		this.contributions	= [,]
		this.adviceDefs		= [,]
		
		map := Type:ServiceDef[][:]
		serviceDefs.each |def, id| {
			map.getOrAdd(def.serviceType) { ServiceDef[,] }.add(def)
		}
		this.typeToServiceDefs = StrategyRegistry(map)
	}

	new make(ObjLocator objLocator, ThreadStashManager stashManager, ModuleDef moduleDef) {
		threadStash = stashManager.createStash(moduleName(moduleDef.moduleId))
		serviceDefs	:= Str:ServiceDef[:] { caseInsensitive = true }
		
		moduleDef.serviceDefs.each |def| { 
			serviceDefs[def.serviceId] = def
			stat := ServiceStat {
				it.serviceId	= def.serviceId
				it.type			= def.serviceType
				it.scope		= def.scope
				it.proxyDisabled= def.noProxy
				it.lifecycle	= ServiceLifecycle.DEFINED
				it.noOfImpls	= 0
			}		
			setStat(def, stat)
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
		
		map := Type:ServiceDef[][:]
		serviceDefs.each |def, id| {
			map.getOrAdd(def.serviceType) { ServiceDef[,] }.add(def)
		}
		this.typeToServiceDefs = StrategyRegistry(map)		
	}

	// ---- Module Methods ----------------------------------------------------
	
	override ServiceDef? serviceDef(Str serviceId) {
		serviceDefs[serviceId]
	}

    override ServiceDef[] serviceDefsByType(Type serviceType) {
//		typeToServiceDefs.findBestFit(serviceType, false) ?: ServiceDef#.emptyList 
		typeToServiceDefs.findExactMatch(serviceType, false) ?: ServiceDef#.emptyList 
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
				service		:= getService(def)
				
				// if asked, replace the cached VIRTUAL service with a real one
				make4Real	:= forceCreate && getLifecycle(def) == ServiceLifecycle.VIRTUAL

				// create if required
				if (make4Real || service == null) {
					service = create(ctx, def, forceCreate)
					setService(def, service)
				}
				
				return service
			}

			if (def.scope == ServiceScope.perApplication) {
				// Because of recursion (service1 creates service2), you can not create the service
				// inside an actor ('cos the actor will block when it eventually messages itself). 
				// So...
				// TODO: A const service could be created twice if there's a race condition between
				// two threads. This is only dangerous because Gawd knows what those services do in 
				// their ctor or PostInject methods!
				service		:= getService(def)
				
				// if asked, replace the cached VIRTUAL service with a real one
				make4Real	:= forceCreate && getLifecycle(def) == ServiceLifecycle.VIRTUAL
				
				// create if required
				if (make4Real || service == null) {
					
					// keep the tracker in the current thread
					service = create(ctx, def, forceCreate)
	
					// double check service existence
					// in a race condition, the 2st service created wins (why not?)
					setService(def, service)
				}
				
				return service
			}
			
			throw WtfErr("What scope is {$def.scope}???")
		}
	}
	
	override Str:ServiceStat serviceStats() {
		stats := ((Str:ServiceStat) getStatState |state->Str:ServiceStat| { 
			state.stats.toImmutable
		}).rw
		
		stats = stats.map |ServiceStat stat->ServiceStat| {
			if (stat.scope != ServiceScope.perThread)
				return stat
			// override with threaded lifecycle
			lifecycle := getServiceState(stat.scope) |state->ServiceLifecycle| { return state.life.get(stat.serviceId, ServiceLifecycle.DEFINED) }
			return stat.withLifecyle(lifecycle)
		}
		
		return stats
	}
	
	override Void clear() {
		withServiceState(ServiceScope.perApplication) |state| { state.clear }
		withServiceState(ServiceScope.perThread) 	  |state| { state.clear }
	}

	// ---- Private Methods ----------------------------------------------------
	
    private Obj create(InjectionCtx ctx, ServiceDef def, Bool forceCreate) {
		if (ctx.objLocator.options["disableProxies"] == true)
			forceCreate = true
		
		if (!forceCreate && def.proxiable && getLifecycle(def) == ServiceLifecycle.DEFINED) {
			return ctx.track("Creating VIRTUAL Service '$def.serviceId'") |->Obj| {
				proxyBuilder 	:= (ServiceProxyBuilder) objLocator.trackServiceById(ctx, ServiceIds.serviceProxyBuilder)
				service			:= proxyBuilder.buildProxy(ctx, def)
				
				setLifecycle(def, ServiceLifecycle.VIRTUAL)
				return service
			}
		}
		
		return ctx.track("Creating REAL Service '$def.serviceId'") |->Obj| {
	        creator := def.createServiceBuilder
	        service := creator.call(ctx)
			
			setLifecycle(def, ServiceLifecycle.CREATED)
			return service
	    }	
    }

	private Obj? getService(ServiceDef def) {
		getServiceState(def.scope) |state->Obj?| { state.services[def.serviceId] }
	}

	private Void setService(ServiceDef def, Obj service) {
		withServiceState(def.scope) |state| { state.services[def.serviceId] = service }
	}

	private Void setStat(ServiceDef def, ServiceStat stat) {
		withStatState |state| { state.stats[def.serviceId] = stat }
		if (def.scope != ServiceScope.perInjection)
			withServiceState(def.scope) |state| { state.life[def.serviceId] = stat.lifecycle }
	}

	private ServiceLifecycle getLifecycle(ServiceDef def) {
		// threaded services will return null on first call, so default to DEFINED
		getServiceState(def.scope) |state->ServiceLifecycle| { state.life.get(def.serviceId, ServiceLifecycle.DEFINED) }
	}

	private Void setLifecycle(ServiceDef def, ServiceLifecycle lifecycle) {
		if (def.scope == ServiceScope.perInjection)
			return

		withServiceState(def.scope) |state| { state.life[def.serviceId] = lifecycle }
		
		withStatState|state| { 
			status := state.stats[def.serviceId].withIncImpls
			if (lifecycle > status.lifecycle)
				status = status.withLifecyle(lifecycle)
			state.stats[def.serviceId] = status
		}
	}

	private Void withServiceState(ServiceScope scope, |ModuleServices| state) {
		switch (scope) {
			case ServiceScope.perApplication:
				appServices.withState(state)
		    
			case ServiceScope.perThread:
				state(threadServices)
		
			default:
				throw WtfErr("(With) Wot scope is ${scope}?")
		}
	}

	private Obj? getServiceState(ServiceScope scope, |ModuleServices->Obj?| state) {
		switch (scope) {
			case ServiceScope.perApplication:
				return appServices.getState(state)
		    
			case ServiceScope.perThread:
				return state(threadServices)
		
			default:
				throw WtfErr("(Get) Wot scope is ${scope}?")
		}
	}
	
	private Str moduleName(Str modId) {
		modId.contains("::") ? modId[(modId.index("::")+1)..-1] : modId 
	}
	
	private Void withStatState(|ModuleStats| state) {
		serviceStat.withState(state)
	}

	private Obj getStatState(|ModuleStats->Obj| state) {
		serviceStat.getState(state)
	}
}

internal class ModuleServices {
	private OneShotLock 			lock		:= OneShotLock("Registry has been shutdown")
	private Str:Obj 				pServices	:= Utils.makeMap(Str#, Obj#)
	private Str:ServiceLifecycle	pLife		:= Utils.makeMap(Str#, ServiceLifecycle#)
	
	Str:Obj	services() {
		lock.check
		return pServices
	}
	
	Str:ServiceLifecycle life() {
		lock.check
		return pLife
	}
	
	Void clear() {
		lock.lock
		pServices.clear
		pLife.clear
	}
}

internal class ModuleStats {
	Str:ServiceStat stats		:= Utils.makeMap(Str#, ServiceStat#)
}
