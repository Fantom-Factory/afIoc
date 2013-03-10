
internal class ServiceBinderImpl : ServiceBinder, ServiceBindingOptions {

	private OneShotLock 	lock := OneShotLock()
	
	private ModuleDefImpl	moduleDef
	private Method 			bindMethod

	private Str? 			serviceId
	private Type? 			serviceMixin
	private Type? 			serviceImpl
//	private Bool?			eagerLoadFlag
	private |ObjLocator->Obj|? 		source
	private Str? 			description

	new make(ModuleDefImpl moduleDef, Method bindMethod) {
		this.moduleDef	= moduleDef
		this.bindMethod = bindMethod
		clear
	}



	// ---- ServiceBinder Method ------------------------------------------------------------------
	
    override ServiceBindingOptions bind(Type serviceMixin, Type serviceImpl) {
        lock.check
        flush

        this.serviceMixin	= serviceMixin
        this.serviceImpl 	= serviceImpl
//        this.eagerLoadFlag	= serviceImpl.hasFacet(EagerLoad#)
        this.serviceId 		= serviceMixin.name

        return this
    }	
	
	override ServiceBindingOptions bindImpl(Type serviceType) {
		if (serviceType.isMixin) {
			try {
				expectedImplName 	:= serviceType.qname + "Impl"
				implType 			:= Type.find(expectedImplName)
				
				if (implType.isMixin || !implType.fits(serviceType)) 
					throw IocErr(IocMessages.noServiceMatchesType(serviceType))

				return bind(serviceType, implType)
				
			} catch (UnknownTypeErr ex) {
				throw IocErr(IocMessages.couldNotFindImplType(serviceType))
			}
		}

		return bind(serviceType, serviceType);
	}	
	
	override ServiceBindingOptions bindBuilder(Type serviceInterface, |->Obj| builder) {
        lock.check
        flush

        this.serviceId 		= serviceInterface.name
        this.serviceMixin 	= serviceInterface
//        this.eagerLoadFlag	= false
        this.source 		= builder
        this.description	= builder.toStr
        return this
    }		

	
	
	// ---- ServiceBindingOptions Methods ---------------------------------------------------------

	override This withId(Str id) {
        lock.check
        serviceId = id
        return this
	}

	override This withSimpleId() {
        if (serviceImpl == null)
			throw ArgErr("No defined implementation class to generate simple id from.")
        return withId(serviceImpl.name)		
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

		// source will be null when the implementation class is provided; non-null when using
		// a ServiceBuilder callback
		if (source == null)
			// sets source and description
			createStandardConstructorBuilder

		serviceDef := ServiceDefImpl() {
			it.serviceId 	= this.serviceId
			it.serviceType 	= this.serviceMixin
//			it.isEagerLoad 	= this.eagerLoadFlag
			it.source		= this.source
			it.description	= this.description
		}

		moduleDef.addServiceDef(serviceDef)
		clear
	}
	
	private Void clear() {
		serviceId 		= null
		serviceMixin	= null
		serviceImpl		= null
//		eagerLoadFlag	= null
		source 			= null
		description		= null
	}
	
	private Void createStandardConstructorBuilder() {
		// lock down the service Impl type so it can't change behind our backs
		serviceImplType	:= this.serviceImpl
		description 	 = "Standard Constructor Builder"
		source 			 = |ObjLocator objLocator -> Obj| {
			InternalUtils.autobuild(objLocator, serviceImplType)
		}
	}	
}

