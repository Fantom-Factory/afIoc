
internal class ServiceBinderImpl : ServiceBinder, ServiceBindingOptions {
	private const static Log log := Utils.getLog(ServiceBinderImpl#)
	private OneShotLock 	lock := OneShotLock(IocMessages.serviceDefined)
	
	private ModuleDef		moduleDef
	private Method 			bindMethod
	|ServiceDefMutable serviceDef| addServiceDef

	private Str? 			serviceId
	private Type? 			serviceMixin
	private Type? 			serviceImpl
	private ServiceScope? 	scope
	private Bool? 			noProxy
	private |OpTracker, ObjLocator->Obj|?	source
	private Str? 			description

	new make(Method bindMethod, ModuleDef moduleDef, |ServiceDefMutable serviceDef| addServiceDef) {
		this.addServiceDef = addServiceDef
		this.bindMethod = bindMethod
		this.moduleDef = moduleDef
		clear
	}


	// ---- ServiceBinder Methods -----------------------------------------------------------------
	
    override ServiceBindingOptions bind(Type serviceMixin, Type? serviceImpl := null) {
        lock.check
        flush

		serviceTypes := verifyServiceImpl(serviceMixin, serviceImpl)

        this.serviceMixin	= serviceTypes[0]
        this.serviceImpl 	= serviceTypes[1]
        this.serviceId 		= serviceTypes[0].qname

        return this
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

	override This withScope(ServiceScope scope) {
		this.scope = scope
		return this
	}

	override This withoutProxy() {
		this.noProxy = true
		return this
	}
	

	// ---- Other Methods -------------------------------------------------------------------------
	
	Void finish() {
		lock.lock
		flush
	}
	
	protected Void flush() {
		if (serviceMixin == null)
			return

		setDefaultScope

		serviceDef := ServiceDefMutable() {
			it.id 			= this.serviceId
			it.moduleId		= this.moduleDef.moduleId
			it.type 		= this.serviceMixin
			it.scope		= this.scope
			it.proxy		= this.noProxy ? ServiceProxy.never : ServiceProxy.always
			it.builderData	= this.serviceImpl
		}

		addServiceDef(serviceDef)
		clear
	}

	static internal Type[] verifyServiceImpl(Type serviceMixin, Type? serviceImpl := null) {
		if (serviceImpl == null) {
			if (serviceMixin.isAbstract) {
				expectedImplName 	:= serviceMixin.qname + "Impl"
				serviceImpl			= Type.find(expectedImplName, false)
				
				if (serviceImpl == null)
					throw IocErr(IocMessages.couldNotFindImplType(serviceMixin))
			} else {
				// assume the mixin was actually the impl
				serviceImpl = serviceMixin
			}
		}

		if (serviceImpl.isMixin) 
			throw IocErr(IocMessages.bindImplNotClass(serviceImpl))

		if (!serviceImpl.fits(serviceMixin)) 
			throw IocErr(IocMessages.bindImplDoesNotFit(serviceMixin, serviceImpl))

		return [serviceMixin, serviceImpl]
	}
	
	private Void clear() {
		serviceId 		= null
		serviceMixin	= null
		serviceImpl		= null
		source 			= null
		scope 			= null
		description		= null
		noProxy			= false
	}
	
	private Void setDefaultScope() {
		if (scope != null)
			return
		scope = serviceImpl.isConst ? ServiceScope.perApplication : ServiceScope.perThread 
	}
}

