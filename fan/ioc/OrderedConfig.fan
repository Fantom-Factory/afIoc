
** This is passed into module contribution methods to allow the method to, err, contribute!
**
** A service can *collect* contributions in three different ways:
** - As an unordered list of values
** - As an ordered list of values
** - As a map of keys and values
** 
** The service defines the *type* of contribution by declaring a parameterised list or map in its 
** ctor or builder method. Contributions must be compatible with the type.
class OrderedConfig {
	
	private const ServiceDef 	serviceDef
	private const Type 			contribType
	private 	  InjectionCtx	ctx
	private 	  List 			config
	
	internal new make(InjectionCtx ctx, ServiceDef serviceDef, Type contribType) {
		if (contribType.name != "List")
			throw WtfErr("Ordered Contrib Type is NOT list???")
		if (contribType.isGeneric)
			throw IocErr(IocMessages.orderedConfigTypeIsGeneric(contribType, serviceDef.serviceId)) 
		
		this.ctx 			= ctx
		this.serviceDef 	= serviceDef
		this.contribType	= contribType
		this.config 		= contribType.params["V"].emptyList.rw	// TODO: is there a better way?
	}

	** Instantiates an object and adds it as an override. 
	Obj autobuild(Type type) {
		ctx.objLocator.trackAutobuild(ctx, type)
	}

	Void addUnordered(Obj object) {
		config.add(object)
	}	

//	** Adds an ordered object to a service's contribution. Each object has an id, which must be 
//	** unique, that is used for ordering.
//	Void addOrdered(Str id, Obj object, Str[] constraints := [,]) {
//	}
//
//	** Overrides a contributed ordered object. The original override must exist.
//	Void overrideOrdered(Str id, Obj object, Str[] constraints := [,]) {
//	}

	internal Void contribute(InjectionCtx ctx, Contribution contribution) {
		contribution.contributeOrdered(ctx, this)
	}
	
	internal List getConfig() {
		config
	}	
}
