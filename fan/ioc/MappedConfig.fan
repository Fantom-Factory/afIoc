
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
	private			Obj:Obj?			config
	private			Obj:MappedOverride	overrides 
	private			TypeCoercer			typeCoercer
	private			Int					overrideCount
	
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
		this.typeCoercer	= TypeCoercer()
		this.overrideCount	= 1
	}

	** A util method to instantiate an object, injecting any dependencies. See `Registry.autobuild`.  
	Obj autobuild(Type type, Obj?[] ctorArgs := Obj#.emptyList) {
		return ctx.objLocator.trackAutobuild(type, ctorArgs)
	}

	** Fantom Bug: http://fantom.org/sidewalk/topic/2163#c13978
	@Operator 
	private Obj? get(Obj key) { null }

	** Adds a keyed object to the service's configuration.
	** An attempt is made to coerce the key / value to the map type.
	@Operator
	This set(Obj key, Obj? val) {
		key = validateKey(key, false)
		val = validateVal(val)

		if (config.containsKey(key))
			throw IocErr(IocMessages.configMappedKeyAlreadyDefined(key.toStr))

		config[key] = val
		return this
	}

	** Adds all the mapped objects to a service's configuration.
	** An attempt is made to coerce the keys / values to the map type.
	This setAll(Obj:Obj? objects) {
		objects.each |val, key| {
			set(key, val)
		}
		return this
	}
	
	** Overrides an existing contribution by its key. The key must exist.
	** An attempt is made to coerce the override key / value to the map type.
	** 
	** Note: Override keys may a Str
	** 
	** Note: If a 'newId' is supplied then this override itself may be overridden by other 
	** contributions. 3rd party libraries, when overriding, should always supply a 'newId'.
	** 
	** @since 1.2.0
	This setOverride(Obj existingKey, Obj? newValue, Obj? newKey := null) {
		if (newKey == null)
			newKey = "OverrideKey${overrideCount}"
		overrideCount = overrideCount + 1
		
		newKey 		= validateKey(newKey, true)
		existingKey = validateKey(existingKey, true)
		newValue	= validateVal(newValue)

		if (overrides.containsKey(existingKey))
		 	throw IocErr(IocMessages.configOverrideKeyAlreadyDefined(existingKey.toStr, overrides[existingKey].key.toStr))

		if (config.containsKey(newKey))
		 	throw IocErr(IocMessages.configOverrideKeyAlreadyExists(newKey.toStr))

		if (overrides.vals.map { it.key }.contains(newKey))
		 	throw IocErr(IocMessages.configOverrideKeyAlreadyExists(newKey.toStr))

		overrides[existingKey] = MappedOverride(newKey, newValue)
		return this
	}

	** A special kind of override whereby, should this be the last override applied, the value is 
	** removed from the configuration.
	** 
	** Note: If a 'newKey' is supplied then this override itself may be overridden by other 
	** contributions. 3rd party libraries, when overriding, should always supply a 'newKey'.
	** 
	** @since 1.4.0
	This remove(Obj existingKey, Obj? newKey := null) {
		setOverride(existingKey, Orderer.delete, newKey)
	}
	
	** dynamically invoked
	internal Void contribute(InjectionCtx ctx, Contribution contribution) {
		contribution.contributeMapped(this)
	}

	** dynamically invoked
	internal Map getConfig() {
		keys := Utils.makeMap(keyType, keyType)
		config.each |val, key| { keys[key] = key }
		
		// don't alter the class state so getConfig() may be called more than once
		Obj:Obj? config := this.config.dup

		InjectionCtx.track("Applying config overrides to '$serviceDef.serviceId'") |->| {
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
						
						InjectionCtx.log("'${overrideKey}' overrides '${existingKey}'")
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

		return config.exclude |val -> Bool| { val == Orderer.delete }
	}

	internal Int size() {
		config.size
	}

	private Obj validateKey(Obj key, Bool isOverrideKey) {
		if (key.typeof.fits(keyType))
			return key
		
		if (isOverrideKey)
			return key

		if (typeCoercer.canCoerce(key.typeof, keyType))
			return typeCoercer.coerce(key, keyType)

		// implicit isOverrideKey == true
		// hmm... looking for an edge case scenario that'll make me un-comment this.
		// as it is, all tests pass.
//		if (key.typeof.fits(Str#))
//			return key

		throw IocErr(IocMessages.mappedConfigTypeMismatch("key", key.typeof, keyType))
	}

	private Obj? validateVal(Obj? val) {
		if (val == Orderer.delete)
			return val

		if (val == null) {
			if (!valType.isNullable)
				throw IocErr(IocMessages.mappedConfigTypeMismatch("value", null, valType))
			return val			
		}

		if (val.typeof.fits(valType))
			return val

		if (typeCoercer.canCoerce(val.typeof, valType))
			return typeCoercer.coerce(val, valType)

		// special case for empty lists - as Obj[,] does not fit Str[,], we make a new Str[,] 
		if (val.typeof.name == "List" && valType.name == "List" && (val as List).isEmpty)
			return valType.params["V"].emptyList

		throw IocErr(IocMessages.mappedConfigTypeMismatch("value", val.typeof, valType))
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
	Obj key; Obj? val
	new make(Obj key, Obj? val) {
		this.key = key
		this.val = val
	}
	override Str toStr() {
		"[$key:$val]"
	}
}
