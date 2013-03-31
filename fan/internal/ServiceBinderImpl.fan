
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

		setDefaultScope

		serviceDef := StandardServiceDef() {
			// lock down the service Impl type so it can't change behind our backs
			// or... I could Func.bind()
			serviceImplType	:= this.serviceImpl
			sId 			:= this.serviceId

			it.serviceId 	= this.serviceId
			it.moduleId 	= this.moduleDef.moduleId
			it.serviceType 	= this.serviceMixin
//			it.isEagerLoad 	= this.eagerLoadFlag
			it.scope		= this.scope
			it.description 	= "'$sId' : Standard Ctor Builder"
			it.source 		= |InjectionCtx ctx->Obj| {
				ctx.track("Creating Serivce '$sId' via a standard ctor autobuild") |->Obj| {
					log.info("Creating Service '$sId'")
					return InjectionUtils.autobuild(ctx, serviceImplType)
				}
			}			
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
}

