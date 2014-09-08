using concurrent

** Meta info that defines a service
// TODO: rename to ServiceMeta? ServiceWrapper 
internal const class ServiceDef {	
	const Str 			serviceId
	const Type			serviceType
	const ServiceScope	serviceScope	
	const ServiceProxy	serviceProxy
	const |->Obj|		serviceBuilder
	const Str			description
	
	// -- null for BareBones ctor --
	private const ObjLocator?	objLocator
			const Method[]?		adviceMethods
			const Method[]?		contribMethods
	private const AtomicInt?	implCountRef	:= AtomicInt(0)
	private const ObjectRef?	lifecycleRef
	private const ObjectRef?	serviceImplRef
	private const ObjectRef?	serviceProxyRef
	
	private const Str 	unqualifiedServiceId
	private const Type 	serviceTypeNonNull
	
	new makeBareBones(|This|in) {
		in(this)		
		this.unqualifiedServiceId	= unqualify(serviceId)
		this.serviceTypeNonNull		= serviceType.toNonNullable
	}
		
	new make(ObjLocator objLocator, ThreadLocalManager localManager, SrvDef srvDef, Obj? serviceImpl) {
		this.objLocator		= objLocator
		this.serviceId		= srvDef.id
		this.serviceType	= srvDef.type
		this.serviceScope	= srvDef.scope
		this.serviceProxy	= srvDef.proxy
		this.adviceMethods	= srvDef.adviceMeths
		this.contribMethods	= srvDef.contribMeths
		this.description	= "wotever"
		
		if (srvDef.buildData is Type) {
			serviceImplType		:= (Type) srvDef.buildData
			this.serviceBuilder	= ServiceBuilders.fromCtorAutobuild(this, serviceImplType)
			this.description	= "$serviceId : via Ctor Autobuild (${serviceImplType.qname})"
		} 	
		else if (srvDef.buildData is Method) {
			builderMethod		:= (Method) srvDef.buildData
			this.serviceBuilder	= ServiceBuilders.fromBuildMethod(this, builderMethod)
			this.description	= "$serviceId : via Builder Method (${builderMethod.qname})"
		} 
		else		
			this.serviceBuilder	= srvDef.buildData
		
		if (srvDef.overridden)
			this.description	+= " (Overridden)"
		
		if (srvDef.desc != null)
			this.description = srvDef.desc
		
		if (this.serviceScope == ServiceScope.perApplication && !serviceType.isConst)
			throw IocErr(IocMessages.perAppScopeOnlyForConstClasses(serviceType))

		if (srvDef.buildData == null)
			serviceBuilder = |->Obj| { 
				throw IocErr("Can not create BuiltIn service '$serviceId'") 
			}

		this.unqualifiedServiceId	= unqualify(serviceId)
		this.serviceTypeNonNull		= serviceType.toNonNullable
		
		defLifecycle		:= srvDef.builtIn ? ServiceLifecycle.builtin : ServiceLifecycle.defined
		this.lifecycleRef	= ObjectRef(localManager.createRef("{$serviceId}.lifecycle"),	serviceScope, null, defLifecycle)
		this.serviceImplRef	= ObjectRef(localManager.createRef("{$serviceId}.impl"), 		serviceScope, serviceImpl)
		this.serviceProxyRef= ObjectRef(localManager.createRef("{$serviceId}.proxy"),		serviceScope, null)
		
		// TODO: throw err if proxy but not mixin
	}
	
	Bool matchesId(Str serviceId) {
		this.serviceId.equalsIgnoreCase(serviceId) || this.unqualifiedServiceId.equalsIgnoreCase(unqualify(serviceId))
	}

	Bool matchesType(Type serviceType) {
		serviceTypeNonNull.fits(serviceType.toNonNullable)
	}

	Void contribute(ConfigurationImpl config) {
		contribMethods?.each |method| {
			InjectionTracker.track("Gathering configuration of type $config.contribType") |->| {
				sizeBefore := config.size
				
				InjectionUtils.callMethod(method, null, [Configuration(config)])
				
				config.cleanupAfterModule
				sizeAfter := config.size
				InjectionTracker.log("Added ${sizeAfter-sizeBefore} contributions")
			}
		}
	}	

	// ---- Service Build Methods ----

	// Because of recursion (service1 creates service2), you can not create the service 
	// inside an actor - 'cos the actor will block when it eventually messages itself. So...
	// We could use afConcurrent::Synchronised to allow re-enterant locks but then threaded 
	// services would be created and stored in the wrong thread. (We'd also have to copy 
	// over all the thread stacks.)
	
	// TODO: A const service could be created twice if there's a race condition between two 
	// threads - but only one is stored. 
	// This is ONLY dangerous because gawd knows what those services do in their ctor and 
	// @PostInject methods!

	Obj newInstance(ServiceProxy proxy) {
		InjectionTracker.withServiceDef(this) |->Obj| {
			(proxy == ServiceProxy.always)
				? getOrMakeProxyService(false)
				: getOrMakeRealService(false)
		}
	}
	Obj getRealService() {
		InjectionTracker.withServiceDef(this) |->Obj| {
			getOrMakeRealService(true)
		}
	}
	Obj getService() {
		lastDef 	:= InjectionTracker.peekServiceDef
		proxiable	:= serviceProxy != ServiceProxy.never && serviceType.isMixin
		needsAdvice	:= adviceMethods != null && !adviceMethods.isEmpty
		needsProxy	:= lastDef?.serviceScope == ServiceScope.perApplication && serviceScope == ServiceScope.perThread && InjectionTracker.injectionCtx.injectionKind.isFieldInjection

		if (needsAdvice && !proxiable)
			throw IocErr(IocMessages.threadScopeInAppScope(lastDef.serviceId, serviceId))

		if (needsProxy && !proxiable)
			throw IocErr(IocMessages.threadScopeInAppScope(lastDef.serviceId, serviceId))

		return InjectionTracker.withServiceDef(this) |->Obj| {
			(needsAdvice || needsProxy || serviceProxy == ServiceProxy.always) 
				? getOrMakeProxyService(true)
				: getOrMakeRealService(true)
		}
	}	
	
	ServiceDefinition toServiceDefinition() {
		ServiceDefinition {
			it.serviceId	= this.serviceId
			it.serviceType	= this.serviceType
			it.serviceScope	= this.serviceScope
			it.serviceProxy	= this.serviceProxy
			it.lifecycle	= this.serviceLifecycle
			it.noOfImpls	= this.implCountRef.val
			it.toStr		= this.description
		}
	}

	private Obj getOrMakeRealService(Bool useCache) {
		if (useCache) {
			exisiting := serviceImplRef.object
			if (exisiting != null)
				return exisiting
		}

		return InjectionTracker.track("Creating REAL Service '$serviceId'") |->Obj| {
	        service := serviceBuilder.call()
			incImplCount
			
			if (useCache) {
				serviceImplRef.object = service
				lifecycleRef.object   = ServiceLifecycle.created
			}
			return service
	    }	
	}

	private Obj getOrMakeProxyService(Bool useCache) {
		if (useCache) {
			exisiting := serviceProxyRef.object
			if (exisiting != null)
				return exisiting
		}
		
		return InjectionTracker.track("Creating VIRTUAL Service '$serviceId'") |->Obj| {
			proxyBuilder 	:= (ServiceProxyBuilder) objLocator.trackServiceById(ServiceProxyBuilder#.qname, true)
			proxy			:= proxyBuilder.createProxyForService(this)
			
			if (useCache) {
				serviceProxyRef.object	= proxy
				lifecycleRef.object 	= ServiceLifecycle.proxied
			}
			return proxy
		}
	}
	
	ServiceLifecycle serviceLifecycle {
		get { lifecycleRef.object }
		set { lifecycleRef.object = it }
	}
	
	Void incImplCount() {
		implCountRef.incrementAndGet
	}

	Void shutdown() {
		serviceImplRef.object 	= null
		serviceProxyRef.object	= null
	}
	
	override Str toStr() {
		description
	}
	
	override Int hash() {
		serviceId.hash
	}

	override Bool equals(Obj? obj) {
		serviceId == (obj as ServiceDef)?.serviceId
	}
	
	private static Str unqualify(Str id) {
		id.contains("::") ? id[(id.index("::")+2)..-1] : id
	}
}

// TODO: rename to ServiceDef
internal class SrvDef {
	Str				id
	Type?			type
	Str 			moduleId	// needed for err msgs

	Obj?			buildData	// type or method
	ServiceScope?	scope
	ServiceProxy?	proxy
	Bool			overridden
	Str?			overrideRef
	Bool			overrideOptional

	Bool			builtIn
	Str?			desc
	
	Method[]?		adviceMeths
	Method[]?		contribMeths

	private const Str 	unqualifiedId
	private const Type?	typeNonNull

	new make(|This| in) {
		in(this) 
		unqualifiedId 	= unqualify(id)
		typeNonNull		= type?.toNonNullable
	}
	
	Void addAdviceDef(AdviceDef adviceDef) {
		if (adviceMeths == null)
			adviceMeths = Method[,]
		adviceMeths.add(adviceDef.advisorMethod)
	}

	Void addContribDef(ContributionDef contribDef) {
		if (contribMeths == null)
			contribMeths = Method[,]
		contribMeths.add(contribDef.method)
	}
	
	Bool matchesId(Str serviceId) {
		this.id.equalsIgnoreCase(serviceId) || this.unqualifiedId.equalsIgnoreCase(unqualify(serviceId))
	}

	Bool matchesType(Type serviceType) {
		typeNonNull.fits(serviceType.toNonNullable)
	}

	ServiceDef toServiceDef(ObjLocator objLocator, ThreadLocalManager localManager, Obj? impl) {
		if (builtIn) {
			proxy = ServiceProxy.never

			if (scope == null)
				scope = ServiceScope.perApplication
			
			if (desc == null)
				desc = "$id : BuiltIn Service"
		}

		return ServiceDef(objLocator, localManager, this, impl)
	}

	Void applyOverride(SrvDef serviceOverride) {
		if (serviceOverride.type != null && !serviceOverride.type.fits(type))
			throw IocErr(IocMessages.serviceOverrideDoesNotFitServiceDef(id, serviceOverride.type, type))

		if (serviceOverride.buildData is Type && !((Type) serviceOverride.buildData).fits(type))
			throw IocErr(IocMessages.serviceOverrideDoesNotFitServiceDef(id, serviceOverride.buildData, type))
		
		if (serviceOverride.buildData != null)
			this.buildData = serviceOverride.buildData

		if (serviceOverride.scope != null)
			this.scope = serviceOverride.scope

		if (serviceOverride.proxy != null)
			this.proxy = serviceOverride.proxy

		this.overridden = true
	}

	override Str toStr() { id }
	
	private static Str unqualify(Str id) {
		id.contains("::") ? id[(id.index("::")+2)..-1] : id
	}
}

