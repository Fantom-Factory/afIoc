
** Passed to 'AppModule' 'defineServices()' methods to add and override service definitions.
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
	
	** Defines a service of the given type. The service defaults to the following attributes:
	**  - **id** - the qualified name of the service type 
	**  - **scope** - 'perApplication', or 'perThread' if the service type is non-const 
	**  - **proxy** - 'ifRequried'
	** 
	** All options may be refined in the returned 'ServiceDefinitionOptions'. 
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

	** Override values in an existing service definition.
	** 
	** The given id may be a service id to override a service, or an override id to override an override.  
	ServiceOverrideOptions overrideById(Str id) {
		serviceDef := SrvDef() {
			it.moduleId 		= _moduleId
			it.id 				= id
			it.scope 			= null 
			it.proxy			= null
			it.buildData		= null
			it.overrideRef		= "${_moduleId}.override${id.capitalize}"
			it.overrideOptional	= false
		}
		
		_addOvrDefFunc(serviceDef)

        return ServiceOverrideOptions(serviceDef)
    }

	** Override values in an existing service definition.
	** 
	** Convenience for 'overrideById(serviceType.qname)'. 
	ServiceOverrideOptions overrideByType(Type serviceType) {
		overrideById(serviceType.qname)
    }
}

** Returned from 'AppModule' `ServiceDefinitions` methods to allow further service options to be set.
** 
** @since 2.0.0
class ServiceDefinitionOptions {
	private SrvDef	serviceDef
	
	internal new make(SrvDef serviceDef) {
		this.serviceDef = serviceDef
	}
	
	** Sets the service id.
	This withId(Str id) {
		serviceDef.id = id
		return this
	}
	
	** Sets the service id to the qualified name of the service implementation class. 
	This withImplId(Str id) {
		implType := (Type) serviceDef.buildData
		serviceDef.id = implType.qname
		return this
	}

	** Sets the scope of the service.
	This withScope(ServiceScope scope) {
		serviceDef.scope = scope
		return this
	}
	
	** Sets the proxy strategy for the service.
	This withProxy(ServiceProxy proxy := ServiceProxy.always) {
		serviceDef.proxy = proxy
		return this
	}
}

** Returned from 'AppModule' `ServiceDefinitions` methods to allow further override options to be set.
** 
** @since 2.0.0
class ServiceOverrideOptions {
	private SrvDef	serviceDef
	
	internal new make(SrvDef serviceDef) {
		this.serviceDef = serviceDef
	}
	
	** Overrides the service implementation with the given type.
	This withImpl(Type implType) {
		if (implType.isMixin) 
			throw IocErr(IocMessages.bindImplNotClass(implType))

		serviceDef.buildData = implType
		return this
	}

	** Overrides the scope of the service.
	This withScope(ServiceScope scope) {
		serviceDef.scope = scope
		return this
	}
	
	** Overrides the proxy strategy for the service.
	This withProxy(ServiceProxy proxy := ServiceProxy.always) {
		serviceDef.proxy = proxy
		return this
	}
	
	** Sets an id for this override definition so others may override this override.
	This withOverrideId(Str overrideId) {
		serviceDef.overrideRef = overrideId
		return this
	}
	
	** If 'true' makes this override optional. As in no error is thrown if the service id does not exist. 
	** Useful for overriding 3rd party libraries that may or may not exist.
	This optional(Bool optional := true) {
		serviceDef.overrideOptional = optional
		return this
	}
}
