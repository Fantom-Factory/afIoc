
** Passed into module contribution methods to allow the method to, err, contribute!
**
** A service can *collect* contributions in three different ways:
** - As an unordered list of values
** - As an ordered list of values
** - As a map of keys and values
** 
** The service defines the *type* of contribution by declaring a parameterised list or map in its 
** ctor or builder method. Contributions must be compatible with the type.
class MappedConfig {
	
	internal const	Type 				contribType
	private  const 	ServiceDef 			serviceDef
	private 	  	InjectionCtx		ctx
	private			Obj:Obj				config
	private			Obj:MappedOverride	overrides 
	
	internal new make(InjectionCtx ctx, ServiceDef serviceDef, Type contribType) {
		if (contribType.name != "Map")
			throw WtfErr("Ordered Contrib Type is NOT map???")
		if (contribType.isGeneric)
			throw IocErr(IocMessages.mappedConfigTypeIsGeneric(contribType, serviceDef.serviceId)) 
		
		this.ctx 			= ctx
		this.serviceDef 	= serviceDef
		this.contribType	= contribType
		this.config 		= Utils.makeMap(keyType, valType)
		this.overrides		= Utils.makeMap(keyType, MappedOverride#)
	}

	** A util method to instantiate an object, injecting any dependencies. See `Registry.autobuild`.  
	Obj autobuild(Type type, Obj?[] ctorArgs := Obj#.emptyList) {
		return ctx.objLocator.trackAutobuild(ctx, type, ctorArgs)
	}
	
	** Adds a keyed object to the service's configuration.
	Void addMapped(Obj key, Obj val) {
		key = validateKey(key, false)
		val = validateVal(val)

		if (config.containsKey(key))
			throw IocErr(IocMessages.configMappedKeyAlreadyDefined(key.toStr))

		config[key] = val
	}
	
	** Adds all the mapped objects to a service's configuration.
	Void addMappedAll(Obj:Obj objects) {
		objects.each |val, key| {
			addMapped(key, val)
		}
	}
	
	** Overrides an existing contribution by its key. The key must exist.
	** 
	** @since 1.2
	Void addOverride(Obj existingKey, Obj overrideKey, Obj overrideVal) {
		overrideKey = validateKey(overrideKey, true)
		existingKey = validateKey(existingKey, true)
		overrideVal	= validateVal(overrideVal)

		if (overrides.containsKey(existingKey))
		 	throw IocErr(IocMessages.configOverrideKeyAlreadyDefined(existingKey.toStr, overrides[existingKey].key.toStr))

		if (config.containsKey(overrideKey))
		 	throw IocErr(IocMessages.configOverrideKeyAlreadyExists(overrideKey.toStr))

		if (overrides.vals.map { it.key }.contains(overrideKey))
		 	throw IocErr(IocMessages.configOverrideKeyAlreadyExists(overrideKey.toStr))

		overrides[existingKey] = MappedOverride(overrideKey, overrideVal)
	}

	internal Void contribute(InjectionCtx ctx, Contribution contribution) {
		contribution.contributeMapped(ctx, this)
	}

	internal Map getConfig() {
		keys := Utils.makeMap(keyType, keyType)
		config.each |val, key| { keys[key] = key }
		
		// don't alter the class state so getConfig() may be called more than once
		Obj:Obj config := this.config.dup

		ctx.track("Applying config overrides to '$serviceDef.serviceId'") |->| {
			// normalise keys -> map all keys to orig key and apply overrides
			Obj:MappedOverride norm := overrides.dup
			found := true
			while (!norm.isEmpty && found) {
				found = false
				norm = norm.exclude |val, existingKey| {
					overrideKey := val.key
					if (keys.containsKey(existingKey)) {
						keys[overrideKey] = keys[existingKey]
						found = true
						
						ctx.log("'${overrideKey}' overrides '${existingKey}'")
						config[keys[existingKey]] = val.val
						return true
					} else {
						return false
					}
				}
			}

			if (!norm.isEmpty) {
				overrideKeys := norm.vals.map { it.key.toStr }.join(", ")
				existingKeys := norm.keys.map { it.toStr }.join(", ")
				throw IocErr(IocMessages.contribOverrideDoesNotExist(existingKeys, overrideKeys))
			}
		}

		return config
	}

	internal Int size() {
		config.size
	}
	
	Obj validateKey(Obj key, Bool isOverrideKey) {
		if (!key.typeof.fits(keyType)) {
			if (!isOverrideKey)
				throw IocErr(IocMessages.mappedConfigTypeMismatch("key", key.typeof, keyType))
			if (!key.typeof.fits(Str#))	// implicit isOverrideKey == true
				throw IocErr(IocMessages.mappedConfigTypeMismatch("key", key.typeof, keyType))			
		}
		return key
	}

	Obj validateVal(Obj val) {
		if (!val.typeof.fits(valType)) {
			// special case for empty lists - as Obj[,] does not fit Str[,], we make a new Str[,] 
			if (val.typeof.name == "List" && valType.name == "List" && (val as List).isEmpty)
				val = valType.params["V"].emptyList
			else
				throw IocErr(IocMessages.mappedConfigTypeMismatch("value", val.typeof, valType))
		}
		return val
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

internal class MappedOverride {
	Obj key; Obj val
	new make(Obj key, Obj val) {
		this.key = key
		this.val = val
	}
	override Str toStr() {
		"[$key:$val]"
	}
}
