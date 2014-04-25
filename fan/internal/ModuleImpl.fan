using concurrent::AtomicInt
using concurrent::AtomicRef

internal const class ModuleImpl : Module {

	override const Str					moduleId	
	private  const OneShotLock 			regShutdown		:= OneShotLock("Registry has shutdown")
	private  const Str:ModuleState		serviceState
	private  const Contribution[]		contributions
	private  const AdviceDef[]			adviceDefs
	private  const ObjLocator			objLocator
	private  const StrategyRegistry		typeToServiceDefs

	new makeBuiltIn(ObjLocator objLocator, ThreadStashManager stashManager, Str moduleId, ServiceDef:Obj? services) {
		threadStash := stashManager.createStash(ServiceIds.builtInModuleId)
		srvState 	:= (Str:ModuleState) Utils.makeMap(Str#, ModuleState#)
		services.each |impl, def| {
			srvState[def.serviceId] = ModuleState(threadStash, def, impl, ServiceLifecycle.BUILTIN)
		}

		this.serviceState 	= srvState
		this.moduleId		= moduleId
		this.objLocator 	= objLocator
		this.adviceDefs		= [,]
		this.contributions	= [,]
		
		map := Type:ServiceDef[][:]
		srvState.each |state, id| {
			map.getOrAdd(state.def.serviceType) { ServiceDef[,] }.add(state.def)
		}
		this.typeToServiceDefs = StrategyRegistry(map)
	}

	new make(ObjLocator objLocator, ThreadStashManager stashManager, ModuleDef moduleDef) {
		threadStash := stashManager.createStash(moduleName(moduleDef.moduleId))
		srvState 	:= (Str:ModuleState) Utils.makeMap(Str#, ModuleState#)
		moduleDef.serviceDefs.each |def| {
			srvState[def.serviceId] = ModuleState(threadStash, def, null, ServiceLifecycle.DEFINED)
		}
		
		this.serviceState 	= srvState		
		this.moduleId		= moduleDef.moduleId
		this.objLocator 	= objLocator
		this.adviceDefs		= moduleDef.adviceDefs
		this.contributions	= moduleDef.contributionDefs.map |contrib| { 
			ContributionImpl {
				it.serviceId 	= contrib.serviceId
				it.serviceType 	= contrib.serviceType
				it.method		= contrib.method
				it.objLocator 	= objLocator
			}
		}
		
		map := Type:ServiceDef[][:]
		srvState.each |state, id| {
			map.getOrAdd(state.def.serviceType) { ServiceDef[,] }.add(state.def)
		}
		this.typeToServiceDefs = StrategyRegistry(map)		
	}

	// ---- Module Methods ----------------------------------------------------
	
	override ServiceDef? serviceDefByQualifiedId(Str serviceId) {
		serviceState[serviceId]?.def
	}

	override ServiceDef[] serviceDefsById(Str serviceId, Str unqualifiedId) {
		sIdLower := serviceId.lower
		return serviceState.vals.findAll |state| {
			state.def.matchesId(sIdLower, unqualifiedId)
		}.map { it.def }
	}

    override ServiceDef[] serviceDefsByType(Type serviceType) {
		typeToServiceDefs.findChildren(serviceType) 
    }

	override Contribution[] contributionsByServiceDef(ServiceDef serviceDef) {
		regShutdown.check
		return contributions.findAll {
			// service def maybe null if contribution is optional
			it.serviceDef?.serviceId == serviceDef.serviceId
		}
	}
	
	override AdviceDef[] adviceByServiceDef(ServiceDef serviceDef) {
		regShutdown.check
		return adviceDefs.findAll {
			it.matchesServiceId(serviceDef.serviceId)
		}
	}
	
	override Obj? service(ServiceDef def, Bool returnReal) {
		regShutdown.check
		// we're going deeper!
		return InjectionTracker.withServiceDef(def) |->Obj?| {

			// Because of recursion (service1 creates service2), you can not create the service inside an actor ('cos 
			// the actor will block when it eventually messages itself). So...
			// TODO: A const service could be created twice if there's a race condition between two threads. This is 
			// only dangerous because Gawd knows what those services do in their ctor or PostInject methods!
			if (def.scope == ServiceScope.perApplication) {
				return getOrMakeService(def, returnReal, true)
			}
			
			if (def.scope == ServiceScope.perThread) {
				return getOrMakeService(def, returnReal, true)
			}
			
			if (def.scope == ServiceScope.perInjection) {
				return getOrMakeService(def, returnReal, false)
			}
			
			throw WtfErr("What scope is {$def.scope}???")
		}
	}
	
	override Str:ServiceStat serviceStats() {
		serviceState.map |state| {
			ServiceStat {
				it.serviceId	= state.def.serviceId
				it.serviceType	= state.def.serviceType
				it.scope		= state.def.scope
				it.proxyDisabled= state.def.noProxy
				it.lifecycle	= state.lifecycle
				it.noOfImpls	= state.implCount
			}
		}
	}
	
	override Void shutdown() {
		regShutdown.lock
		serviceState.each { it.shutdown }
	}

	override Bool hasServices() {
		// it may have only contributions or advisors 
		!serviceState.isEmpty
	}
	
	// ---- Private Methods ----------------------------------------------------

	private Obj getOrMakeService(ServiceDef def, Bool returnReal, Bool useCache) {
		if (returnReal)
			return getOrMakeRealService(def, useCache)
		if (InjectionTracker.peek(false)?.objLocator?.options?.get("disableProxies") == true)
			return getOrMakeRealService(def, useCache)
		if (!def.proxiable)
			return getOrMakeRealService(def, useCache)
		
		return getOrMakeProxyService(def, useCache)
	}

	private Obj getOrMakeRealService(ServiceDef def, Bool useCache) {
		if (useCache) {
			exisitng := serviceState[def.serviceId].service
			if (exisitng != null)
				return exisitng
		}

		return InjectionTracker.track("Creating REAL Service '$def.serviceId'") |->Obj| {
	        creator := def.createServiceBuilder
	        service := creator.call()
			serviceState[def.serviceId].incImpls
			
			if (useCache) {
				serviceState[def.serviceId].service = service
				serviceState[def.serviceId].lifecycle = ServiceLifecycle.CREATED
			}
			return service
	    }	
	}

	private Obj getOrMakeProxyService(ServiceDef def, Bool useCache) {
		if (useCache) {
			exisitng := serviceState[def.serviceId].proxy
			if (exisitng != null)
				return exisitng
		}
		
		return InjectionTracker.track("Creating VIRTUAL Service '$def.serviceId'") |->Obj| {
			proxyBuilder 	:= (ServiceProxyBuilder) objLocator.trackServiceById(ServiceIds.serviceProxyBuilder)
			proxy			:= proxyBuilder.createProxyForService(def)
			
			if (useCache) {
				serviceState[def.serviceId].proxy = proxy
				serviceState[def.serviceId].lifecycle = ServiceLifecycle.VIRTUAL
			}
			return proxy
		}
	}
	
	private Str moduleName(Str modId) {
		modId.contains("::") ? modId[(modId.index("::")+2)..-1] : modId 
	}	
}

internal const class ModuleState {
	private const ThreadStash 	threadStash
	private const AtomicRef		aLifecycle	:= AtomicRef(null)
	private const AtomicInt		aImplCount	:= AtomicInt(0)
	private const AtomicRef		aImpl		:= AtomicRef(null)
	private const AtomicRef?	aProxy
	
			const ServiceDef	def

	new make(ThreadStash threadStash, ServiceDef def, Obj? impl, ServiceLifecycle lifecycle) {
		this.def = def
		this.threadStash = threadStash
		this.aLifecycle.val = lifecycle
		this.lifecycle = lifecycle	// set threaded
		this.aImpl.val = impl
		if (impl != null) incImpls
		if (!def.noProxy) aProxy = AtomicRef(null)
	}

	Int implCount {
		get { aImplCount.val }
		set { aImplCount.val = it }
	}

	ServiceLifecycle lifecycle {
		// will return null if not created, so default to what we were made with
		get { getObj(aLifecycle, "threadLifecycles") ?: aLifecycle.val }
		set { setObj(aLifecycle, "threadLifecycles", it) }
	}
	
	Obj? service {
		get { getObj(aImpl, "threadImpls") }
		set { setObj(aImpl, "threadImpls", it) }
	}
	
	Obj? proxy {
		// the lazy proxy may be const, but the mixin it implements may NOT be!
		get { getObj(aProxy, "threadProxies") }
		set { setObj(aProxy, "threadProxies", it) }
	}
	
	private Obj? getObj(AtomicRef ref, Str mapName) {
		if (def.scope == ServiceScope.perApplication)
			return ref.val
		if (def.scope == ServiceScope.perThread)
			return threads(mapName)[def.serviceId]
		return null
	}

	private Void setObj(AtomicRef ref, Str mapName, Obj? obj) {
		if (def.scope == ServiceScope.perApplication) 
			ref.val = obj
		if (def.scope == ServiceScope.perThread)
			threads(mapName)[def.serviceId] = obj
	}
	
	Void incImpls() {
		aImplCount.incrementAndGet
	}

	Void shutdown() {
		proxy = null
		service = null
	}
	
	private Str:Obj? threads(Str name) {
		threadStash.get(name) |->[Str:Obj?]| { Str:Obj?[:] }
	}
}
