
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
