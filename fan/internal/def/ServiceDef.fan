using afConcurrent
using concurrent

** Meta info that defines a service
internal const class ServiceDef : LazyProxy {
	const Bool			isIocService

	const Str 			serviceId
	const Type			serviceType
	const ServiceScope?	serviceScope	// autobuilds are null
	const ServiceProxy	serviceProxy
	const |->Obj|		serviceBuilder
	const Str			description
	
	// -- null for BareBones ctor --
	private const ObjLocator?	objLocator
			const AtomicBool	configTypeGot	:= AtomicBool(false)
			const AtomicRef		configTypeRef	:= AtomicRef()
			const |->Type?|?	configTypeFunc
			const Method[]?		contribMethods
			const Method[]?		adviceMethods
	private const AtomicInt		implCountRef	:= AtomicInt(0)
	private const ObjectRef?	lifecycleRef
	private const ObjectRef?	serviceImplRef
	private const ObjectRef?	serviceProxyRef
	private const AtomicRef		adviceMap		:= AtomicRef()
	private const AtomicBool	notBuilt		:= AtomicBool(true)
	
	private const Str 	unqualifiedServiceId
	private const Type 	serviceTypeNonNull

	
	
	// ---- Ctor Methods --------------------------------------------------------------------------
	
	new makeForAutobuild(ObjLocator? objLocator, |This|in) {
		in(this)
		this.objLocator 			= objLocator	// nullable for testing
		this.isIocService			= false
		this.unqualifiedServiceId	= unqualify(serviceId)
		this.serviceTypeNonNull		= serviceType.toNonNullable
	}

	new makeForProxybuild(ObjLocator objLocator, ThreadLocalManager localManager, |This|in) {
		in(this)
		this.objLocator 			= objLocator
		this.isIocService			= false
		this.unqualifiedServiceId	= unqualify(serviceId)
		this.serviceTypeNonNull		= serviceType.toNonNullable
		this.serviceImplRef			= ObjectRef(localManager.createRef("{$serviceId}.impl"), serviceScope)
		this.notBuilt				= AtomicBool(true)
	}

	new makeForService(ObjLocator objLocator, ThreadLocalManager localManager, SrvDef srvDef, Obj? serviceImpl) {
		this.objLocator			= objLocator
		this.isIocService		= true
		this.serviceId			= srvDef.id
		this.serviceType		= srvDef.type
		this.serviceScope		= srvDef.scope
		this.serviceProxy		= srvDef.proxy
		this.adviceMethods		= srvDef.adviceMeths
		this.contribMethods		= srvDef.contribMeths
		this.description		= "wotever"
		
		if (srvDef.buildData is Type) {
			serviceImplType		:= (Type) srvDef.buildData
			ctorArgs			:= srvDef.ctorArgs
			fieldVals			:= srvDef.fieldVals
			this.serviceBuilder	= objLocator.serviceBuilders.fromCtorAutobuild(serviceId, serviceImplType, ctorArgs, fieldVals, true).toImmutable
			this.description	= "$serviceId : via Ctor Autobuild (${serviceImplType.qname})"
			this.configTypeFunc	= |->Type?| {
				// because we're gonna search through the services looking for ctor param matches, we need to delay
				// ctor finding until all the services are defined
				ctor := objLocator.serviceBuilders.findAutobuildConstructor(serviceImplType, ctorArgs?.map { it?.typeof }, true)
				return findConfigType(ctor)
			}
		} 	
		else if (srvDef.buildData is Method) {
			builderMethod			:= (Method) srvDef.buildData
			this.serviceBuilder		= objLocator.serviceBuilders.fromBuildMethod(serviceId, builderMethod).toImmutable
			this.description		= "$serviceId : via Builder Method (${builderMethod.qname})"
			this.configTypeGot.val	= true
			this.configTypeRef.val	= findConfigType(builderMethod)
		} 
		else
			this.serviceBuilder	= srvDef.buildData

		// don't validate builtin services - they're already built!
		if (serviceImpl != null) {
			this.configTypeGot.val	= true
			this.configTypeRef.val	= null
			// hardcode fudge for DependencyProviders
			if (serviceImpl.typeof == DependencyProvidersImpl#)
				this.configTypeRef.val	= DependencyProvider[]#
		}

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

		if (this.serviceScope == ServiceScope.perApplication)
			this.notBuilt			= AtomicBool(serviceImpl == null)
		
		this.unqualifiedServiceId	= unqualify(serviceId)
		this.serviceTypeNonNull		= serviceType.toNonNullable
		
		defLifecycle		:= srvDef.builtIn ? ServiceLifecycle.builtin : ServiceLifecycle.defined
		this.lifecycleRef	= ObjectRef(localManager.createRef("{$serviceId}.lifecycle"),	serviceScope, null, defLifecycle)
		this.serviceImplRef	= ObjectRef(localManager.createRef("{$serviceId}.impl"), 		serviceScope, serviceImpl)
		this.serviceProxyRef= ObjectRef(localManager.createRef("{$serviceId}.proxy"),		serviceScope)		
	}
	
	// a fudge for bootstrapping DependencyProviders
	Void swapServiceImpl(Obj newImpl) {
		serviceImplRef.val = newImpl
	}
	
	// ---- Service Build Methods -----------------------------------------------------------------

	Obj getService() {
		lastDef 	:= InjectionTracker.peekServiceDef
		proxiable	:= serviceProxy != ServiceProxy.never && serviceType.isMixin
		needsAdvice	:= adviceMethods != null && !adviceMethods.isEmpty
		needsProxy	:= isIocService && lastDef?.serviceScope == ServiceScope.perApplication && serviceScope == ServiceScope.perThread && InjectionTracker.injectionCtx.injectionKind.isFieldInjection

		if (needsAdvice && !proxiable)
			throw IocErr(IocMessages.threadScopeInAppScope(lastDef.serviceId, serviceId))

		if (needsProxy && !proxiable)
			throw IocErr(IocMessages.threadScopeInAppScope(lastDef.serviceId, serviceId))

		return (needsAdvice || needsProxy || serviceProxy == ServiceProxy.always) 
			? getProxyService
			: getRealService
	}
	
	override Obj getRealService() {
		if (serviceScope == ServiceScope.perApplication) {
			if (notBuilt.compareAndSet(true, false)) {
				makeRealService
			}
			
			// if being built by another thread, wait for it to finish
			while (serviceImplRef.val == null) {
				InjectionTracker.recursionCheck(this, "Waiting for ${serviceId} to be built") |->| {
					Actor.sleep(10ms)
				}
			}
			
			return serviceImplRef.val
		}
		
		if (serviceScope == ServiceScope.perThread) {
			if (serviceImplRef.val == null)
				makeRealService
			
			return serviceImplRef.val
		}
		
		throw WtfErr("What scope is ${serviceScope}???")
	}

	Obj getProxyService() {
		exisiting := serviceProxyRef.val
		if (exisiting 
			!= null)
			return exisiting
	
		return InjectionTracker.track("Creating PROXY for Service '$serviceId'") |->Obj| {
			proxy	:= proxyBuilder.createProxyForService(this) 

			serviceProxyRef.val	= proxy
			serviceLifecycle 	= ServiceLifecycle.proxied
			return proxy
		}
	}

	Obj autobuild() {
		return InjectionTracker.recursionCheck(this, "Autobuilding '$serviceId'") |->Obj| {
			return serviceBuilder.call()
		}
	}

	Obj autoproxy() {
		return InjectionTracker.track("Autoproxy '$serviceId'") |->Obj| {
	        return proxyBuilder.createProxyForService(this)
		}
	}

	private Obj makeRealService() {
		return InjectionTracker.recursionCheck(this, "Creating REAL Service '$serviceId'") |->Obj| {
			service := serviceBuilder.call()
			incImplCount
			serviceImplRef.val = service
			serviceLifecycle   = ServiceLifecycle.created
			return service
		}
	}

	private ServiceProxyBuilder proxyBuilder() {
		objLocator.trackServiceById(ServiceProxyBuilder#.qname, true)
	}

//	Void terminate() {
//		serviceLifecycle   = ServiceLifecycle.builtin		
//	}


	// ---- Service Configuration Methods ---------------------------------------------------------

	Void validate() {
		if (configType == null && contribMethods != null && !contribMethods.isEmpty)
			throw IocErr(IocMessages.contributionMethodsNotWanted(serviceId, contribMethods))
	}

	Type? configType() {
		if (configTypeGot.val == false) {
			configTypeRef.val = configTypeFunc()
			configTypeGot.val = true
		}
		return configTypeRef.val
	}
	
	Obj? gatherConfiguration() {
		configType := configType
		if (configType == null)
			return null
		
		// continue even if we have no contrib methods, so an empty map / list is made
		
		config := ConfigurationImpl(objLocator, this, configType)
		
		contribMethods?.each |method| {
			InjectionTracker.track("Gathering configuration of type $config.contribType") |->| {
				sizeBefore := config.size
				
				objLocator.injectionUtils.callMethod(method, null, [Configuration(config)])
				
				config.cleanupAfterModule
				sizeAfter := config.size
				InjectionTracker.log("Added ${sizeAfter-sizeBefore} contributions")
			}
		}

		if (configType.name == "List")
			return config.toList
		if (configType.name == "Map")
			return config.toMap
		
		throw WtfErr("${configType.name} is neither a List nor a Map")
	}
	
	
	
	// ---- Service Advice Methods ----------------------------------------------------------------
	
	override Obj? callMethod(Method method, Obj?[] args) {
		// lazily load advice
		if (adviceMap.val == null)
			adviceMap.val = gatherAdvice.toImmutable
		
		adviceMap 	:= ([Method:|MethodInvocation invocation -> Obj?|[]]) adviceMap.val
		advice 		:= adviceMap[method]

		if (advice == null)
			return method.callOn(getRealService, args)
		
		return MethodInvocation {
			it.service	= getRealService
			it.aspects	= advice
			it.method	= method
			it.args		= args
			it.index	= 0
		}.invoke
	}
	
	Method:|MethodInvocation invocation -> Obj?|[] gatherAdvice() {
		adviceMap := [Method:|MethodInvocation invocation -> Obj?|[]][:]
		
		if (adviceMethods == null || adviceMethods.isEmpty)
			return adviceMap
		
		// create a MethodAdvisor for each (non-Obj) method to be advised
		methodAdvisors := (MethodAdvisor[]) serviceType.methods.rw
			.exclude { Obj#.methods.contains(it) }
			.map |m->MethodAdvisor| { MethodAdvisor(m) }
				
		// call the module @Advise methods, filling up the MethodAdvisors
		InjectionTracker.track("Gathering advice for service '$serviceId'") |->| {
			adviceMethods.each { 
				objLocator.injectionUtils.callMethod(it, null, [methodAdvisors])
			}
		}

		// convert the method advisors into a handy, easy access, map 
		methodAdvisors.each {
			if (!it.aspects.isEmpty)
				adviceMap[it.method] = it.aspects
		}
		
		return adviceMap
	}
	

	
	// ---- Misc Methods ---------------------------------------------------------------------------
	
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
	
	Bool matchesId(Str serviceId) {
		this.serviceId.equalsIgnoreCase(serviceId) || this.unqualifiedServiceId.equalsIgnoreCase(unqualify(serviceId))
	}

	Bool matchesType(Type serviceType) {
		serviceTypeNonNull.fits(serviceType)
	}
	
	ServiceLifecycle serviceLifecycle {
		get { lifecycleRef.val }
		set { if (lifecycleRef != null && lifecycleRef.val < ServiceLifecycle.builtin) lifecycleRef.val = it }
	}
	
	Void incImplCount() {
		implCountRef.incrementAndGet
	}

	Void shutdown() {
		serviceImplRef.val 	= null
		serviceProxyRef.val	= null
	}
	
	private Str unqualify(Str id) {
		id.contains("::") ? id[(id.index("::")+2)..-1] : id
	}
	
	internal Type? findConfigType(Method? buildMethod) {
		if (buildMethod == null || buildMethod.params.isEmpty)
			return null
		
		// Config HAS to be the first param
		paramType := buildMethod.params[0].type
		if (paramType.name == "List")
			return paramType
		if (paramType.name == "Map")
			return paramType
		return null
	}
	
	override Int hash() {
		serviceId.hash
	}

	override Bool equals(Obj? obj) {
		serviceId == (obj as ServiceDef)?.serviceId
	}
	
	override Str toStr() {
		description
	}
}



internal class SrvDef {
	Str				id {
		set {
			&id = it
			unqualifiedId 	= unqualify(it)
		}
	}
	Type?			type
	Str 			moduleId	// needed for err msgs

	Obj?			buildData	// type or method
	ServiceScope?	scope
	ServiceProxy?	proxy
	Bool			overridden
	Str?			overrideRef
	Bool			overrideOptional
	Obj?[]?			ctorArgs
	[Field:Obj?]?	fieldVals

	Bool			builtIn
	Str?			desc
	
	Method[]?		adviceMeths
	Method[]?		contribMeths

	private Str 	unqualifiedId
	private const Type?	typeNonNull

	new make(|This| in) {
		in(this) 
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

		return ServiceDef.makeForService(objLocator, localManager, this, impl)
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

		if (serviceOverride.ctorArgs != null)
			this.ctorArgs = serviceOverride.ctorArgs

		if (serviceOverride.fieldVals != null)
			this.fieldVals = serviceOverride.fieldVals

		this.overridden = true
	}

	override Str toStr() { id }
	
	private static Str unqualify(Str id) {
		id.contains("::") ? id[(id.index("::")+2)..-1] : id
	}
}

