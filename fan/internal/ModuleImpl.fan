using concurrent::AtomicInt
using concurrent::AtomicRef
using afConcurrent::LocalMap

internal const class ModuleImpl : Module {

	override const Str					moduleId	
	private  const OneShotLock 			regShutdown		:= OneShotLock("Registry has shutdown")
	private  const Str:ServiceState		serviceState
	private  const Contribution[]		contributions
	private  const AdviceDef[]			adviceDefs
	private  const ObjLocator			objLocator

	new make(ObjLocator objLocator, ThreadLocalManager localManager, ModuleDef moduleDef, [Type:Obj]? readyMade) {
		localMap := localManager.createMap(moduleName(moduleDef.moduleId))
		srvState 	:= (Str:ServiceState) Utils.makeMap(Str#, ServiceState#)
		moduleDef.serviceDefs.each |def| {
			impl := readyMade?.get(def.type)
			life  := (readyMade == null) ? ServiceLifecycle.defined : ServiceLifecycle.builtin
			srvState[def.id] = ServiceState(localMap, def.toServiceDef(this), impl, life)
		}
		
		this.serviceState 	= srvState		
		this.moduleId		= moduleDef.moduleId
		this.objLocator 	= objLocator
		this.adviceDefs		= moduleDef.adviceDefs
		this.contributions	= moduleDef.contribDefs.map |contrib| { 
			ContributionImpl {
				it.serviceId 	= contrib.serviceId
				it.serviceType 	= contrib.serviceType
				it.method		= contrib.method
				it.objLocator 	= objLocator
			}
		}
	}

	// ---- Module Methods ----------------------------------------------------

	override ServiceDef[] serviceDefs() {
		serviceState.vals.map { it.def }
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
			
			useCache := !(autobuild ?: def.serviceScope == ServiceScope.perInjection)

			if (returnReal)
				return getOrMakeRealService(def, useCache)

			if (!def.proxiable)
				return getOrMakeRealService(def, useCache)

			return getOrMakeProxyService(def, useCache)
		}
	}
	
	override Str:ServiceDefinition serviceStats() {
		serviceState.map |state| {
			ServiceDefinition {
				it.serviceId	= state.def.serviceId
				it.serviceType	= state.def.serviceType
				it.serviceScope	= state.def.serviceScope
				it.proxyDisabled= state.def.noProxy
				it.lifecycle	= state.lifecycle
				it.noOfImpls	= state.implCount
				it.toStr		= state.def.description
			}
		}
	}
	
	override Void shutdown() {
		regShutdown.lock
		serviceState.each { it.shutdown }
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

internal const class ServiceState {
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
		if (def.serviceScope == ServiceScope.perApplication)
			return ref.val
		if (def.serviceScope == ServiceScope.perThread)
			return localMap["${def.serviceId}.${varName}"]
		return null
	}

	private Void setObj(AtomicRef? ref, Str varName, Obj? obj) {
		if (def.serviceScope == ServiceScope.perApplication && ref != null) 
			ref.val = obj
		if (def.serviceScope == ServiceScope.perThread)
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
