using concurrent::AtomicInt
using concurrent::AtomicRef
using afConcurrent::LocalMap

internal const class ModuleImpl : Module {

	override const Str					moduleId	
	private  const OneShotLock 			regShutdown		:= OneShotLock("Registry has shutdown")
	private  const Str:ModuleState		serviceState
	private  const Contribution[]		contributions
	private  const AdviceDef[]			adviceDefs
	private  const ObjLocator			objLocator
	private  const CachingTypeLookup	typeToServiceDefs

	new makeBuiltIn(ObjLocator objLocator, ThreadLocalManager localManager, Str moduleId, ServiceDef:Obj? services) {
		localMap	:= localManager.createMap(moduleId)
		srvState 	:= (Str:ModuleState) Utils.makeMap(Str#, ModuleState#)
		services.each |impl, def| {
			srvState[def.serviceId] = ModuleState(localMap, def, impl, ServiceLifecycle.builtin)
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
		this.typeToServiceDefs = CachingTypeLookup(map)
	}

	new make(ObjLocator objLocator, ThreadLocalManager localManager, ModuleDef moduleDef) {
		localMap := localManager.createMap(moduleName(moduleDef.moduleId))
		srvState 	:= (Str:ModuleState) Utils.makeMap(Str#, ModuleState#)
		moduleDef.serviceDefs.each |def| {
			srvState[def.serviceId] = ModuleState(localMap, def, null, ServiceLifecycle.defined)
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
		this.typeToServiceDefs = CachingTypeLookup(map)		
	}

	// ---- Module Methods ----------------------------------------------------
	
	override ServiceDef? serviceDefByQualifiedId(Str serviceId) {
		serviceState[serviceId]?.def
	}

	override ServiceDef[] serviceDefsById(Str serviceId) {
		return serviceState.vals.findAll |state| {
			state.def.matchesId(serviceId)
		}.map { it.def }
	}

    override ServiceDef[] serviceDefsByType(Type serviceType) {
		typeToServiceDefs.findChildren(serviceType, false)
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
			it.matchesService(serviceDef)
		}
	}
	
	override Obj? service(ServiceDef def, Bool returnReal, Bool? autobuild) {
		regShutdown.check
		// we're going deeper!
		return InjectionTracker.withServiceDef(def) |->Obj?| {

			// Because of recursion (service1 creates service2), you can not create the service 
			// inside an actor - 'cos the actor will block when it eventually messages itself. So...
			// We could use afConcurrent::Synchronised to allow re-enterant locks but then threaded 
			// services would be created and stored in the wrong thread. (We'd also have to copy 
			// over all the thread stacks.)

			// TODO: A const service could be created twice if there's a race condition between two 
			// threads - but only one is stored. 
			// This is ONLY dangerous because gawd knows what those services do in their ctor and 
			// @PostInject methods!
			
			useCache := !(autobuild ?: def.scope == ServiceScope.perInjection)

			if (returnReal)
				return getOrMakeRealService(def, useCache)

			if (!def.proxiable)
				return getOrMakeRealService(def, useCache)

			return getOrMakeProxyService(def, useCache)
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

	private Obj getOrMakeRealService(ServiceDef def, Bool useCache) {
		if (useCache) {
			exisitng := serviceState[def.serviceId].service
			if (exisitng != null)
				return exisitng
		}

		return InjectionTracker.track("Creating REAL Service '$def.serviceId'") |->Obj| {
	        service := def.serviceBuilder.call()
			serviceState[def.serviceId].incImpls
			
			if (useCache) {
				serviceState[def.serviceId].service = service
				serviceState[def.serviceId].lifecycle = ServiceLifecycle.created
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
			proxyBuilder 	:= (ServiceProxyBuilder) objLocator.trackServiceById(ServiceProxyBuilder#.qname, true)
			proxy			:= proxyBuilder.createProxyForService(def)
			
			if (useCache) {
				serviceState[def.serviceId].proxy = proxy
				serviceState[def.serviceId].lifecycle = ServiceLifecycle.proxied
			}
			return proxy
		}
	}
	
	private Str moduleName(Str modId) {
		modId.contains("::") ? modId[(modId.index("::")+2)..-1] : modId 
	}	
}

internal const class ModuleState {
	private const LocalMap		localMap
	private const AtomicRef		aLifecycle	:= AtomicRef(null)
	private const AtomicInt		aImplCount	:= AtomicInt(0)
	private const AtomicRef		aImpl		:= AtomicRef(null)
	private const AtomicRef?	aProxy
			const ServiceDef	def

	new make(LocalMap localMap, ServiceDef def, Obj? impl, ServiceLifecycle lifecycle) {
		this.localMap		= localMap
		this.def 			= def
		this.aLifecycle.val = lifecycle
		this.lifecycle 		= lifecycle	// set threaded
		this.aImpl.val 		= impl
		if (impl != null) incImpls
		if (!def.noProxy) aProxy = AtomicRef(null)
	}

	Int implCount {
		get { aImplCount.val }
		set { aImplCount.val = it }
	}

	ServiceLifecycle lifecycle {
		// will return null if not created, so default to what we were made with
		get { getObj(aLifecycle, "lifecycle") ?: aLifecycle.val }
		set { setObj(aLifecycle, "lifecycle", it) }
	}
	
	Obj? service {
		get { getObj(aImpl, "impl") }
		set { setObj(aImpl, "impl", it) }
	}
	
	Obj? proxy {
		// the lazy proxy may be const, but the mixin it implements may NOT be!
		get { getObj(aProxy, "proxy") }
		set { setObj(aProxy, "proxy", it) }
	}
	
	private Obj? getObj(AtomicRef? ref, Str varName) {
		if (def.scope == ServiceScope.perApplication)
			return ref.val
		if (def.scope == ServiceScope.perThread)
			return localMap["${def.serviceId}.${varName}"]
		return null
	}

	private Void setObj(AtomicRef? ref, Str varName, Obj? obj) {
		if (def.scope == ServiceScope.perApplication && ref != null) 
			ref.val = obj
		if (def.scope == ServiceScope.perThread)
			localMap["${def.serviceId}.${varName}"] = obj
	}
	
	Void incImpls() {
		aImplCount.incrementAndGet
	}

	Void shutdown() {
		proxy = null
		service = null
	}	
}
