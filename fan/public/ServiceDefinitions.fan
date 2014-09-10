
** Passed to module 'defineServices()' methods to add and override service definitions.
** 
** Service builder methods are the default means to define services. 
** But if your service can be 'autobuilt' (and most can!) then the 'defineServices()' method is a quick and easy alternative. 
** 
** If your service is a class named 'MyServiceClass' then it may be defined as follows:
** 
** pre>
** class AppModule {
**     static Void defineServices(ServiceDefinitions defs) {
**         defs.add(MyServiceClass#)
**     } 
** }
** <pre
** 
** If your service is a mixin with a default implementation class then it may be defined as follows: 
** 
** pre>
** static Void defineServices(ServiceDefinitions defs) {
**     defs.add(MyService#, MyServiceImpl#)
** } 
** <pre
**
** If the implementation class has the same name as the mixin but with an 'Impl' suffix (as does the example above) then it may be defined with the shorthand notation of:
** 
** pre>
** static Void defineServices(ServiceDefinitions defs) {
**     defs.add(MyService#)
** } 
** <pre
** 
** Note that the default service id for all services is the *qualified* name of the first parameter.
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
	
	This withProxy(ServiceProxy proxy := ServiceProxy.always) {
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
	
	This withProxy(ServiceProxy proxy := ServiceProxy.always) {
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
