
** Passed to module 'defineServices()' methods to add and override service definitions.
** 
** Service builder methods are the default means to define services. 
** But if your service can be 'autobuilt' (and most can!) then the 'defineServices()' method is a quick and easy alternative. 
** 
** For standard services that can be 'autobuilt', the 'defineServices()' method lets you quickly define them without using builder methods. 
** Services defined with 'defineServices()' must be able to be built     
** Use in your 'AppModule.defineServices(ServiceDefinitions defs) {...}' method  
** If your service implementation is fronted by a mixin, then pass them both in: 
** 
** pre>
** class AppModule {
**     static Void bind(ServiceBinder binder) {
**         binder.bind(MyService#, MyServiceImpl#)
**     } 
** }
** <pre
**
** If your service is just an impl class then you can use the shorter form:
** 
** pre>
** class AppModule {
**     static Void bind(ServiceBinder binder) {
**         binder.bind(MyServiceImpl#)
**     } 
** }
** <pre
** 
** You can also use the shorter form, passing in the mixin, if your Impl class has the same name as your mixin + "Impl".
** 
** The default service id is the unqualified name of the service mixin (or impl if no mixin was provided).
** 
** This is an adaptation of ideas from [Guice]`http://code.google.com/p/google-guice/`.
** 
** @since 2.0.0
class ServiceDefinitions {
	
	private |SrvDef|	_addSvrDefFunc
	private |SrvDef|	_addOvrDefFunc
	private Str			_moduleId
	
	internal new make(Str moduleId, |SrvDef| addSvrDefFunc, |SrvDef| addOvrDefFunc) {
		this._moduleId = moduleId
		this._addSvrDefFunc = addSvrDefFunc
		this._addOvrDefFunc = addOvrDefFunc
	}
	
	ServiceDefinitionOptions add(Type serviceType, Type? serviceImplType := null) {
		if (serviceImplType == null) {
			if (serviceType.isAbstract) {
				expectedImplName 	:= serviceType.qname + "Impl"
				serviceImplType		= Type.find(expectedImplName, false)
				
				if (serviceImplType == null)
					throw IocErr(IocMessages.couldNotFindImplType(serviceType))
			} else {
				// assume the mixin was actually the impl
				serviceImplType = serviceType
			}
		}

		if (serviceImplType.isMixin) 
			throw IocErr(IocMessages.bindImplNotClass(serviceImplType))

		if (!serviceImplType.fits(serviceType)) 
			throw IocErr(IocMessages.bindImplDoesNotFit(serviceType, serviceImplType))

		serviceDef := SrvDef() {
			it.moduleId		= _moduleId
			it.id 			= serviceType.qname
			it.type 		= serviceType
			it.scope		= serviceType.isConst ? ServiceScope.perApplication : ServiceScope.perThread 
			it.proxy		= ServiceProxy.ifRequired
			it.buildData	= serviceImplType
		}
		
		_addSvrDefFunc(serviceDef)

        return ServiceDefinitionOptions(serviceDef)
    }

	ServiceOverrideOptions overrideById(Str serviceId) {
		serviceDef := SrvDef() {
			it.moduleId 		= _moduleId
			it.id 				= serviceId
			it.scope 			= null 
			it.proxy			= null
			it.buildData		= null
			it.overrideRef		= "${_moduleId}.override${serviceId.capitalize}."
			it.overrideOptional	= false
		}
		
		_addOvrDefFunc(serviceDef)

        return ServiceOverrideOptions(serviceDef)
    }

	ServiceOverrideOptions overrideByType(Type serviceType) {
		serviceDef := SrvDef() {
			it.moduleId 		= _moduleId
			it.id 				= serviceType.qname
			it.scope 			= null 
			it.proxy			= null
			it.buildData		= null
			it.overrideRef		= "${_moduleId}.override${serviceType.name.capitalize}."
			it.overrideOptional	= false
		}
		
		_addOvrDefFunc(serviceDef)

        return ServiceOverrideOptions(serviceDef)
    }
}

** Returned from `ServiceDefinitions` methods to allow further service options to be set.
** 
** @since 2.0.0
class ServiceDefinitionOptions {
	private SrvDef	serviceDef
	
	internal new make(SrvDef serviceDef) {
		this.serviceDef = serviceDef
	}
	
	This withId(Str id) {
		serviceDef.id = id
		return this
	}
	
	This withImplId(Str id) {
		if (serviceDef.buildData isnot Type)
			throw Err("wutgh")
		implType := (Type) serviceDef.buildData
		serviceDef.id = implType.qname
		return this
	}

	This withScope(ServiceScope scope) {
		serviceDef.scope = scope
		return this
	}
	
	This withProxy(ServiceProxy proxy) {
		serviceDef.proxy = proxy
		return this
	}
}

** Returned from `ServiceDefinitions` methods to allow further override options to be set.
** 
** @since 2.0.0
class ServiceOverrideOptions {
	private SrvDef	serviceDef
	
	internal new make(SrvDef serviceDef) {
		this.serviceDef = serviceDef
	}
	
	This withImpl(Type implType) {
		if (implType.isMixin) 
			throw IocErr(IocMessages.bindImplNotClass(implType))

		serviceDef.buildData = implType
		return this
	}

	This withScope(ServiceScope scope) {
		serviceDef.scope = scope
		return this
	}
	
	This withProxy(ServiceProxy proxy) {
		serviceDef.proxy = proxy
		return this
	}
	
	This withOverrideId(Str overrideId) {
		serviceDef.overrideRef = overrideId
		return this
	}
	
	This optional(Bool optional := true) {
		serviceDef.overrideOptional = optional
		return this
	}
}
