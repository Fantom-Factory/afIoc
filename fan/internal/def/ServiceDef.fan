using concurrent

** Meta info that defines a service 
internal const class ServiceDef {	
	const Str 			serviceId
	const Type			serviceType
	const ServiceScope	serviceScope	
	const ServiceProxy	serviceProxy
	const |->Obj|		serviceBuilder
	const Str			description

	private const Str 	unqualifiedServiceId
	private const Type 	serviceTypeNonNull
	
	// -- null for BareBones ctor --
	private const ObjLocator?	objLocator
			const AdviceDef[]?	adviceDefs
			const Method[]?		contribMethods
	private const AtomicInt?	implCountRef	:= AtomicInt(0)
	private const ObjectRef?	lifecycleRef
	private const ObjectRef?	serviceImplRef
	private const ObjectRef?	serviceProxyRef
	
	
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
		this.adviceDefs		= srvDef.adviceDefs
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

	Obj getService() {
		service(this, false, null)
	}	
	Obj getRealService() {
		service(this, true, null)		
	}
	Obj newInstance() {
		service(this, false, true)		
	}
	
	// FIXME proxy kill me
	Bool proxiable() {
		// if we proxy a per 'perInjection' into an app scoped service, is it perApp or perThread!??
		// Yeah, exactly! Just don't allow it.
		serviceProxy != ServiceProxy.never && serviceType.isMixin && (serviceScope != ServiceScope.perInjection)
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

	// ---- Service ----
	
	private Obj? service(ServiceDef def, Bool returnReal, Bool? autobuild) {
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

	private Obj getOrMakeRealService(ServiceDef def, Bool useCache) {
		if (useCache) {
			exisiting := serviceImplRef.object
			if (exisiting != null)
				return exisiting
		}

		return InjectionTracker.track("Creating REAL Service '$def.serviceId'") |->Obj| {
	        service := def.serviceBuilder.call()
			incImplCount
			
			if (useCache) {
				serviceImplRef.object = service
				lifecycleRef.object   = ServiceLifecycle.created
			}
			return service
	    }	
	}

	private Obj getOrMakeProxyService(ServiceDef def, Bool useCache) {
		if (useCache) {
			exisiting := serviceProxyRef.object
			if (exisiting != null)
				return exisiting
		}
		
		return InjectionTracker.track("Creating VIRTUAL Service '$def.serviceId'") |->Obj| {
			proxyBuilder 	:= (ServiceProxyBuilder) objLocator.trackServiceById(ServiceProxyBuilder#.qname, true)
			proxy			:= proxyBuilder.createProxyForService(def)
			
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
	
	AdviceDef[]?	adviceDefs
	Method[]?		contribMeths

	private const Str 	unqualifiedId
	private const Type?	typeNonNull

	new make(|This| in) {
		in(this) 
		unqualifiedId 	= unqualify(id)
		typeNonNull		= type?.toNonNullable
	}
	
	Void addAdviceDef(AdviceDef adviceDef) {
		if (adviceDefs == null)
			adviceDefs = AdviceDef[,]
		adviceDefs.add(adviceDef)
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

