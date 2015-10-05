
@Js
internal const class LegacyInspector : ModuleInspector {
	
	override Void inspect(RegistryBuilder bob, Obj module) {
		moduleType := module.typeof

		methods := moduleType.methods.rw.sort |Method a, Method b -> Int| { 
			a.name <=> b.name 
		}

		methods.each |method| {
			if (method.params.size == 1 && ServiceDefinitions# == method.params.first.type)
				addServiceDefsFromDefinitions(bob, module, method)
		}
	}
	
	private Void addServiceDefsFromDefinitions(RegistryBuilder bob, Obj module, Method method) {
		serviceDefs := ServiceDefinitions(method.parent, bob._serviceDefs, bob._overrideDefs)
		method.callOn(method.isStatic ? null : module, [serviceDefs])
	}
}

@Js @NoDoc @Deprecated
class ServiceDefinitions {
	
	private Type		_moduleId
	private	SrvDef[]	serviceDefs
	private	OvrDef[]	overrideDefs
	
	internal new make(Type moduleId, SrvDef[] serviceDefs, OvrDef[] overrideDefs) {
		this._moduleId		= moduleId
		this.serviceDefs	= serviceDefs
		this.overrideDefs	= overrideDefs
	}
	
	** Defines a service of the given type. The service defaults to the following attributes:
	**  - **id** - the qualified name of the service type 
	**  - **scope** - 'perApplication', or 'perThread' if the service type is non-const 
	** 
	** All options may be refined in the returned 'ServiceBuilder'. 
	ServiceBuilder add(Type serviceType, Type? serviceImplType := null) {
		bob := ServiceBuilderImpl(_moduleId)
		bob.srvDef.type 		= serviceType
		bob.srvDef.implType		= serviceImplType
		bob.srvDef.id			= serviceType.qname
		bob.srvDef.autobuild	= true
		serviceDefs.add(bob.srvDef)
        return bob
    }

	** Override values in an existing service definition.
	** 
	** The given id may be a service id to override a service, or an override id to override an override.  
	ServiceOverrideBuilder overrideById(Str id) {
        bob := ServiceOverrideBuilderImpl(_moduleId)
		bob.ovrDef.serviceId = id
		overrideDefs.add(bob.ovrDef)
		return bob
    }

	** Override values in an existing service definition.
	** 
	** Convenience for 'overrideById(serviceType.qname)'. 
	ServiceOverrideBuilder overrideByType(Type serviceType) {
        bob := ServiceOverrideBuilderImpl(_moduleId)
		bob.ovrDef.serviceType = serviceType
		overrideDefs.add(bob.ovrDef)
		return bob
    }
}
