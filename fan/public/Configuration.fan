
** Passed into module contribution methods to allow the method to contribute configuration.
** 
** The service defines the *type* of contribution by declaring a parameterised list or map in its 
** ctor or builder method. Contributions must be compatible with the type.
** 
** @since 1.7.0
class Configuration {
	private ConfigurationImpl config

	** By using this wrapped, all the internals are hidden from IDE auto-complete proposals.
	internal new make(ConfigurationImpl config) {
		this.config = config
	}
	
	** A convenience method for `Registry.autobuild`.  
	Obj autobuild(Type type, Obj?[]? ctorArgs := null, [Field:Obj?]? fieldVals := null) {
		registry.autobuild(type, ctorArgs, fieldVals)
	}

	** A convenience method for `Registry.autobuild`.  
	Obj createProxycreateProxy(Type mixinType, Type? implType := null, Obj?[]? ctorArgs := null, [Field:Obj?]? fieldVals := null) {
		registry.createProxy(mixinType, implType, ctorArgs, fieldVals)
	}

	** A convenience method that returns the IoC Registry.
	Registry registry() {
		config.registry
	}

	** Fantom Bug: http://fantom.org/sidewalk/topic/2163#c13978
	@Operator 
	private Obj? get(Obj key) { null }

	** Sets a key / value pair to the service configuration with optional ordering constraints.
	**
	** If the end service configuration is a List, then the keys are discarded and only the values passed use. 
	** In this case, typically 'Str' keys are used for ease of use when overriding / adding constraints.   
	**  
	** Configuration contributions are ordered across modules. 
	** 
	** 'key' and 'value' are coerced to the service's contribution type.
	@Operator
	Constraints set(Obj key, Obj? value) {
		config.set(key, value)
	}

	** Adds a value to the service configuration with optional ordering constraints.
	** 
	** Because the keys of *added* values are unknown, they cannot be overridden. 
	** For that reason it is advised to use 'set()' instead. 
	**  
	** 'value' is coerced to the service's contribution type.
	Constraints add(Obj value) {
		config.add(value)
	}

	** Adds a placeholder. Placeholders are empty configurations used to aid ordering of actual values:
	** 
	** pre>
	**   config.placeholder("end")
	**   config.set("wot", ever).before("end")
	**   config.set("last", last).after("end")
	** <pre
	** 
	** While not very useful in the same contribution method, they become very powerful when used across multiple modules and pods.
	** 
	** Placeholders do not appear in the the resulting configuration and are never seen by the end service. 
	Constraints addPlaceholder(Str key) {
		config.addPlaceholder(key)
	}
	
	** Overrides and replaces a contributed value. 
	** The existing key must exist.
	** 
	** 'existingKey' is the id / key of the value to be replaced. 
	** It may have been initially provided by 'set()' or have be the 'newKey' of a previous override.
	** 
	** 'newKey' does not appear in the the resulting configuration and is never seen by the end service.
	** It is only used as reference to this override, so this override itself may be overridden.
	** 3rd party libraries, when overriding, should always supply a 'newKey'. 
	** 'newKey' may be any 'Obj' instance but sane and intelligent people will *always* pass in a 'Str'.  
	** 
	** 'newValue' is coerced to the service's contribution type.
	Constraints overrideValue(Obj existingKey, Obj? newValue, Obj? newKey := null) {
		config.overrideValue(existingKey, newValue, newKey)
	}
	
	** A special kind of override whereby, should this be the last override applied, the value is 
	** removed from the configuration.
	** 
	** 'existingKey' is the id / key of the value to be replaced. 
	** It may have been initially provided by 'set()' or have be the 'newKey' of a previous override.
	** 
	** 'newKey' does not appear in the the resulting configuration and is never seen by the end service.
	** It is only used as reference to this override, so this override itself may be overridden.
	** 3rd party libraries, when overriding, should always supply a 'newKey'. 
	** 'newKey' may be any 'Obj' instance but sane and intelligent people will *always* pass in a 'Str'.  
	Void remove(Obj existingKey, Obj? newKey := null) {
		config.remove(existingKey, newKey)
	}

	@NoDoc
	override Str toStr() {
		config.toStr
	}	
}

internal class ConfigurationImpl {
	
	internal const	Type 				contribType
	private  const 	ServiceDef 			serviceDef
	private 	  	ObjLocator 			objLocator
	private			Int					impliedCount
	private			Str?				impliedConstraint
	private			Obj:Contrib			allConfig
	private			Obj:Contrib			modConfig
	private			Obj:Contrib			overrides
	private			Int					overrideCount
	private			CachingTypeCoercer	typeCoercer

	internal new make(ObjLocator objLocator, ServiceDef serviceDef, Type contribType) {
		if (contribType.name != "Map" && contribType.name != "List")
			throw WtfErr("Contributions Type is NOT a Map or a List ???")
		if (contribType.isGeneric)
			throw IocErr(IocMessages.contributions_configTypeIsGeneric(contribType, serviceDef.serviceId)) 

		this.contribType	= contribType
		this.serviceDef 	= serviceDef
		this.objLocator 	= objLocator
		this.impliedCount	= 1
		this.allConfig		= Utils.makeMap(Obj#, Contrib#)
		this.modConfig		= Utils.makeMap(Obj#, Contrib#)
		this.overrides		= Utils.makeMap(Obj#, Contrib#)
		this.overrideCount	= 1
		this.typeCoercer	= CachingTypeCoercer()
	}

	Registry registry() {
		(Registry) objLocator
	}

	Constraints set(Obj key, Obj? value) {
		key   = validateKey(key, false)
		value = validateVal(value)
		
		if (modConfig.containsKey(key))
			throw IocErr(IocMessages.contributions_configKeyAlreadyDefined(key.toStr, modConfig[key].val))
		if (allConfig.containsKey(key))
			throw IocErr(IocMessages.contributions_configKeyAlreadyDefined(key.toStr, allConfig[key].val))

		contrib := Contrib(key, value)
		modConfig[key] = contrib 
		return contrib
	}

	Constraints add(Obj value) {
		if (keyType != Str#)
			throw IocErr(IocMessages.contributions_keyTypeNotKnown(keyType))

		key := "afIoc.unordered-" + impliedCount.toStr.padl(2)
		impliedCount++

		return set(key, value)
	}

	Constraints addPlaceholder(Str key) {
		set(key, Orderer.PLACEHOLDER)
	}
	
	Constraints overrideValue(Obj existingKey, Obj? newValue, Obj? newKey := null) {
		if (newKey == null)
			newKey = "afIoc.override-" + overrideCount.toStr.padl(2)
		overrideCount = overrideCount + 1

		newKey 		= validateKey(newKey, true)
		existingKey = validateKey(existingKey, true)
		newValue	= validateVal(newValue)

		if (overrides.containsKey(existingKey))
		 	throw IocErr(IocMessages.contributions_configOverrideKeyAlreadyDefined(existingKey.toStr, overrides[existingKey].key.toStr))

		if (modConfig.containsKey(newKey) || allConfig.containsKey(newKey))
		 	throw IocErr(IocMessages.contributions_configOverrideKeyAlreadyExists(newKey.toStr))

		if (overrides.vals.map { it.key }.contains(newKey))
		 	throw IocErr(IocMessages.contributions_configOverrideKeyAlreadyExists(newKey.toStr))

		contrib := Contrib(newKey, newValue)
		overrides[existingKey] = contrib
		return contrib
	}
	
	Void remove(Obj existingKey, Obj? newKey := null) {
		overrideValue(existingKey, Orderer.DELETE, newKey)
	}


	
	// ---- Internal Methods ----------------------------------------------------------------------
	
	internal Void cleanupAfterModule() {
		modConfig.each { it.finalise }
		modConfig.each { it.findImplied(modConfig) }
		modConfig.each |v, k| { allConfig[k] = v }
	}
	
	internal Int size() {
		allConfig.size
	}

	internal List toList() {
		contribs := orderedContribs
		config   := (Obj?[]) List.make(valueType, contribs.size)
		contribs.each { config.add(it.val) }
		return config
	}

	internal Map toMap() {
		mapType := Map#.parameterize(["K":keyType, "V":valueType])
		config  := (Obj:Obj?) Map.make(mapType) { ordered = true }
		
		orderedContribs.each {
			config[it.key] = it.val
		}
		return config
	}

	private Contrib[] orderedContribs() {
		keys := Utils.makeMap(keyType, keyType)
		allConfig.each |val, key| { keys[key] = key }
		
		// don't alter the class state so getConfig() may be called more than once
		config := (Obj:Contrib) this.allConfig.dup

		InjectionTracker.track("Applying config overrides to '$serviceDef.serviceId'") |->| {
			// normalise keys -> map all keys to orig key and apply overrides
			norm := (Obj:Contrib) this.overrides.dup 
			found := true
			while (!norm.isEmpty && found) {
				found = false
				norm = norm.exclude |val, existingKey| {
					overrideKey := val.key
					if (keys.containsKey(existingKey)) {
						keys[overrideKey] = keys[existingKey]
						found = true
						
						InjectionTracker.log("'${overrideKey}' overrides '${existingKey}'")
						config[keys[existingKey]] = val
						
						// dispose of the override key
						val.key = keys[existingKey]
						return true
					} else {
						return false
					}
				}
			}

			if (!norm.isEmpty) {
				overrideKeys := norm.vals.map { it.key.toStr }.join(", ")
				existingKeys := norm.keys.map { it.toStr }.join(", ")
				throw IocErr(IocMessages.contributions_overrideDoesNotExist(existingKeys, overrideKeys))
			}
		}			
		
		ordered := (Contrib[]) InjectionTracker.track("Ordering configuration contributions") |->Contrib[]| {
			configKeys := config.keys
			orderer := Orderer()
			config.each |val, key| {
				value := (val.val === Orderer.DELETE || val.val === Orderer.PLACEHOLDER) ? val.val : val
				orderer.addOrdered(key, value, val.befores, val.afters)
			}
			return orderer.toOrderedList
		}
		
		return ordered
	}	
	
	
	
	// ---- Helper Methods ------------------------------------------------------------------------

	private Obj validateKey(Obj key, Bool isOverrideKey) {
		// don't use ReflectUtils.fits() - let TypeCoercer do a proper job.
		if (key.typeof.fits(keyType))
			return key
		
		if (isOverrideKey)
			return key

		if (typeCoercer.canCoerce(key.typeof, keyType))
			return typeCoercer.coerce(key, keyType)

		throw IocErr(IocMessages.contributions_configTypeMismatch("key", key.typeof, keyType))
	}

	private Obj? validateVal(Obj? val) {
		if (val === Orderer.DELETE || val === Orderer.PLACEHOLDER)
			return val
		
		if (val == null) {
			if (!valueType.isNullable)
				throw IocErr(IocMessages.contributions_configTypeMismatch("value", null, valueType))
			return val
		}

		// don't use ReflectUtils.fits() - let TypeCoercer do a proper job.
		if (val.typeof.fits(valueType))
			return val

		// empty lists and maps can always be converted
		if (!isEmptyList(val) && !isEmptyMap(val))
			if (!typeCoercer.canCoerce(val.typeof, valueType))
				throw IocErr(IocMessages.contributions_configTypeMismatch("value", val.typeof, valueType))

		return typeCoercer.coerce(val, valueType)
	}
	
	private Bool isEmptyList(Obj val) {
		(val is List) && (((List) val).isEmpty)
	}
	
	private Bool isEmptyMap(Obj val) {
		(val is Map) && (((Map) val).isEmpty)
	}

	private once Type keyType() {
		contribType.name == "Map" ? contribType.params["K"] : Str#
	}

	private once Type valueType() {
		contribType.params["V"]
	}

	@NoDoc
	override Str toStr() {
		"${contribType.name} Configuration of '${contribType.signature}' for '${serviceDef.serviceId}'".replace("sys::", "")
	}	
}
