
internal class ServiceBinderImpl : ServiceBinder, ServiceBindingOptions {
	private const static Log log := Utils.getLog(ServiceBinderImpl#)
	private OneShotLock 	lock := OneShotLock(IocMessages.serviceDefined)
	
	private ModuleDef		moduleDef
	private Method 			bindMethod
	|ServiceDef serviceDef| addServiceDef

	private Str? 			serviceId
	private Type? 			serviceMixin
	private Type? 			serviceImpl
	private ScopeDef? 		scope
//	private Bool?			eagerLoadFlag
	private |OpTracker, ObjLocator->Obj|?	source
	private Str? 			description

	new make(Method bindMethod, ModuleDef moduleDef, |ServiceDef serviceDef| addServiceDef) {
		this.addServiceDef = addServiceDef
		this.bindMethod = bindMethod
		this.moduleDef = moduleDef
		clear
	}



	// ---- ServiceBinder Methods -----------------------------------------------------------------
	
    override ServiceBindingOptions bind(Type serviceMixin, Type serviceImpl) {
        lock.check
        flush

		if (serviceImpl.isMixin) 
			throw IocErr(IocMessages.bindImplNotClass(serviceImpl))

		if (!serviceImpl.fits(serviceMixin)) 
			throw IocErr(IocMessages.bindImplDoesNotFit(serviceMixin, serviceImpl))

        this.serviceMixin	= serviceMixin
        this.serviceImpl 	= serviceImpl
        this.serviceId 		= serviceMixin.name

        return this
    }	
	
	override ServiceBindingOptions bindImpl(Type serviceType) {
		if (serviceType.isMixin) {
			expectedImplName 	:= serviceType.qname + "Impl"
			implType 			:= Type.find(expectedImplName, false)
			
			if (implType == null)
				throw IocErr(IocMessages.couldNotFindImplType(serviceType))

			return bind(serviceType, implType)
		}

		return bind(serviceType, serviceType);
	}

	
	// ---- ServiceBindingOptions Methods ---------------------------------------------------------

	override This withId(Str id) {
        lock.check
        this.serviceId = id
        return this
	}

	override This withSimpleId() {
        withId(serviceImpl.name)		
	}

	override This withScope(ScopeDef scope) {
		if (scope == ScopeDef.perApplication && !serviceImpl.isConst)	// FIXME: test
			throw IocErr(IocMessages.perAppScopeOnlyForConstClasses(serviceImpl))
		this.scope = scope
		return this
	}

//	override This eagerLoad() {
//        lock.check
//        this.eagerLoadFlag = true
//		return this		
//	}
	
	
	
	// ---- Other Methods -------------------------------------------------------------------------
	
	Void finish() {
		lock.lock
		flush
	}
	
	protected Void flush() {
		if (serviceMixin == null)
			return

		// sets source and description
		setDefaultScope
		createStandardConstructorBuilder

		serviceDef := StandardServiceDef() {
			it.serviceId 	= this.serviceId
			it.moduleId 	= this.moduleDef.moduleId
			it.serviceType 	= this.serviceMixin
//			it.isEagerLoad 	= this.eagerLoadFlag
			it.source		= this.source
			it.scope		= this.scope
			it.description	= this.description
		}

		addServiceDef(serviceDef)
		clear
	}
	
	private Void clear() {
		serviceId 		= null
		serviceMixin	= null
		serviceImpl		= null
//		eagerLoadFlag	= null
		source 			= null
		scope 			= null
		description		= null
	}
	
	private Void setDefaultScope() {
		if (scope != null)
			return
		scope = serviceImpl.isConst ? ScopeDef.perApplication : ScopeDef.perThread 
	}
	
	private Void createStandardConstructorBuilder() {
		// lock down the service Impl type so it can't change behind our backs
		// or... I could Func.bind()
		serviceImplType	:= this.serviceImpl
		serviceId		:= this.serviceId
		scope			:= this.scope
		description 	= "'$serviceId' : Standard Ctor Builder"
		source 			 = |OpTracker tracker, ObjLocator objLocator -> Obj| {
			tracker.track("Creating Serivce '$serviceId' via a standard ctor autobuild") |->Obj| {
				log.info("Creating Service '$serviceId'")
				return InjectionUtils.autobuild(tracker, objLocator, serviceImplType, scope)
			}
		}
	}	
}

