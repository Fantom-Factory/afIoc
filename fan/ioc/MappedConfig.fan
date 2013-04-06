
** This is passed into module contribution methods to allow the method to, err, contribute!
**
** A service can *collect* contributions in three different ways:
** - As an unordered list of values
** - As an ordered list of values
** - As a map of keys and values
** 
** The service defines the *type* of contribution by declaring a parameterised list or map in its 
** ctor or builder method. Contributions must be compatible with the type.
class MappedConfig {
	
	internal const	Type 			contribType
	private  const 	ServiceDef 		serviceDef
	private 	  	InjectionCtx	ctx
	private 	  	Map 			config
	
	internal new make(InjectionCtx ctx, ServiceDef serviceDef, Type contribType) {
		if (contribType.name != "Map")
			throw WtfErr("Ordered Contrib Type is NOT map???")
		if (contribType.isGeneric)
			throw IocErr(IocMessages.mappedConfigTypeIsGeneric(contribType, serviceDef.serviceId)) 
		
		this.ctx 			= ctx
		this.serviceDef 	= serviceDef
		this.contribType	= contribType
		this.config 		= (keyType == Str#) 
							? Map.make(contribType) { caseInsensitive = true }
							: Map.make(contribType) { ordered = true }
	}

	** A util method to instantiate an object, injecting any dependencies. See `Registry.autobuild`.  
	Obj autobuild(Type type) {
		ctx.objLocator.trackAutobuild(ctx, type)
	}
	
	** Adds a keyed object to the service's configuration.
	Void addMapped(Obj key, Obj val) {
		keyType := contribType.params["K"]
		valType := contribType.params["V"]
		
		if (!key.typeof.fits(keyType))
			throw IocErr(IocMessages.mappedConfigTypeMismatch("key", key.typeof, keyType))
		if (!val.typeof.fits(valType)) {
			// special case for empty lists - as Obj[,] does not fit Str[,], we make a new Str[,] 
			if (val.typeof.name == "List" && valType.name == "List" && (val as List).isEmpty)
				val = valType.params["V"].emptyList
			else
				throw IocErr(IocMessages.mappedConfigTypeMismatch("value", val.typeof, valType))
		}
		
		config.add(key, val)
	}
	
	** Adds all the mapped objects to a service's configuration.
	Void addMappedAll(Obj:Obj objects) {
		objects.each |val, key| {
			addMapped(key, val)
		}
	}
	
//	** Overrides an existing contribution by its key.
//	Void addMappedOverride(Obj key, Obj value) {
//		
//	}
	
	internal Void contribute(InjectionCtx ctx, Contribution contribution) {
		contribution.contributeMapped(ctx, this)
	}
	
	internal Map getConfig() {
		config
	}
	
	private once Type keyType() {
		contribType.params["K"]
	}
	
	private once Type valType() {
		contribType.params["V"]
	}
	override Str toStr() {
		"MappedConfig of $contribType"
	}	

}
