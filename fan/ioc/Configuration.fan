
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
	
	** A convenience method that instantiates an object, injecting any dependencies. See `Registry.autobuild`.  
	Obj autobuild(Type type, Obj?[]? ctorArgs := null, [Field:Obj?]? fieldVals := null) {
		config.autobuild(type, ctorArgs, fieldVals)
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
	** The constraints string is a CSV list. 
	** Each value must start with the prefix 'BEFORE:' or 'AFTER:'.
	** 
	** pre>
	**   config["Breakfast"] = eggs
	**   config["Dinner"]    = pie
	**   config.set("Lunch", ham, "AFTER: breakfast, BEFORE: dinner")
	** <pre
	**
	** If the configuration uses non-Str keys, then use 'key.toStr()' in the constraint strings.
	**   
	** If the end service configuration is a List, then the keys are discarded and only the values passed in. 
	** Typically, 'Str' keys are used in these situations, for ease of use.  
	**  
	** Configuration contributions are ordered across modules. 
	** 
	** 'key' and 'value' are coerced to the service's contribution type.
	@Operator
	This set(Obj key, Obj? value, Str? constraints := null) {
		config.set(key, value, constraints)
		return this
	}

	** Adds a value to the service configuration with optional ordering constraints.
	** 
	** Because the keys of *added* values are unknown, they cannot be overridden. 
	** For that reason it is advised to use 'set()' instead. 
	**  
	** 'value' is coerced to the service's contribution type.
	@Operator
	This add(Obj value, Str? constraints := null) {
		config.add(value, constraints)
		return this
	}

	** Adds a placeholder. Placeholders are empty configurations used to aid ordering of actual values:
	** 
	** pre>
	**   config.placeholder("end")
	**   config.set("wot", ever, ["BEFORE: end"])
	**   config.set("last", last, ["AFTER: end"])
	** <pre
	** 
	** Placeholders do not appear in the the resulting configuration and is never seen by the end service. 
	This addPlaceholder(Str key, Str? constraints := null) {
		config.addPlaceholder(key, constraints)
		return this
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
	** 'newKey' may be defined as 'Obj' but sane and level headed people will *always* pass in a 'Str'.  
	** 
	** 'newValue' is coerced to the service's contribution type.
	This overrideValue(Obj existingKey, Obj? newValue, Str? newConstraints := null, Obj? newKey := null) {
		config.overrideValue(existingKey, newValue, newConstraints, newKey)
		return this
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
	** 'newKey' may be defined as 'Obj' but sane and level headed people will *always* pass in a 'Str'.  
	This remove(Obj existingKey, Obj? newKey := null) {
		config.remove(existingKey, newKey)
		return this
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
	private			Obj:Contrib			config
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
		this.config			= Utils.makeMap(Obj#, Contrib#)
		this.overrides		= Utils.makeMap(Obj#, Contrib#)
		this.overrideCount	= 1
		this.typeCoercer	= CachingTypeCoercer()
	}
	
	Obj autobuild(Type type, Obj?[]? ctorArgs := null, [Field:Obj?]? fieldVals := null) {
		objLocator.trackAutobuild(type, ctorArgs, fieldVals)
	}

	Registry registry() {
		(Registry) objLocator
	}

	This set(Obj key, Obj? value, Str? constraints := null) {
		key   = validateKey(key, false)
		value = validateVal(value)
		
		if (constraints == null || constraints.isEmpty) {
			constraints = impliedConstraint ?: Str.defVal
			
			// keep an implied ordering for anything that doesn't have its own constraints
			impliedCount++
			impliedConstraint = "after: $key"
		}
		
		if (config.containsKey(key))
			throw IocErr(IocMessages.contributions_configKeyAlreadyDefined(key.toStr))

		config[key] = Contrib(key, value, constraints)
		return this
	}

	This add(Obj value, Str? constraints := null) {
		if (keyType != Str#)
			throw IocErr(IocMessages.contributions_keyTypeNotKnown(keyType))

		key := "afIoc.unordered-" + impliedCount.toStr.padl(2)

		return set(key, value, constraints)
	}

	This addPlaceholder(Str key, Str? constraints := null) {
		set(key, Orderer.placeholder, constraints)
	}
	
	This overrideValue(Obj existingKey, Obj? newValue, Str? newConstraints := null, Obj? newKey := null) {
		if (newKey == null)
			newKey = "afIoc.override-" + overrideCount.toStr.padl(2)
		overrideCount = overrideCount + 1

		newKey 		= validateKey(newKey, true)
		existingKey = validateKey(existingKey, true)
		newValue	= validateVal(newValue)

		if (overrides.containsKey(existingKey))
		 	throw IocErr(IocMessages.contributions_configOverrideKeyAlreadyDefined(existingKey.toStr, overrides[existingKey].key.toStr))

		if (config.containsKey(newKey))
		 	throw IocErr(IocMessages.contributions_configOverrideKeyAlreadyExists(newKey.toStr))

		if (overrides.vals.map { it.key }.contains(newKey))
		 	throw IocErr(IocMessages.contributions_configOverrideKeyAlreadyExists(newKey.toStr))

		overrides[existingKey] = Contrib(newKey, newValue, newConstraints)
		return this
	}
	
	This remove(Obj existingKey, Obj? newKey := null) {
		overrideValue(existingKey, Orderer.delete, null, newKey)
	}


	
	// ---- Internal Methods ----------------------------------------------------------------------

	** dynamically invoked - just a reset method
	internal Void reset() {
		// implied ordering only per contrib method
		impliedConstraint = null
	}	
	
	internal Int size() {
		config.size
	}

	internal List toConfigList() {
		contribs := orderedContribs
		config   := (Obj?[]) List.make(valueType, contribs.size)
		contribs.each { config.add(it.val) }
		return config
	}

	internal Map toConfigMap() {
		mapType := Map#.parameterize(["K":keyType, "V":valueType])
		config  := (Obj:Obj?) Map.make(mapType) { ordered = true }
		
		orderedContribs.each {
			config[it.key] = it.val
		}
		return config
	}

	private Contrib[] orderedContribs() {
		keys := Utils.makeMap(keyType, keyType)
		config.each |val, key| { keys[key] = key }
		
		// don't alter the class state so getConfig() may be called more than once
		config := (Obj:Contrib) this.config.dup

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
			
		// we need to convert ALL keys to string for ordering because the "before: XXX, after: XXX" constraints are strings.
		ordered := (Contrib[]) InjectionTracker.track("Ordering configuration contributions") |->Contrib[]| {
			orderer := Orderer()
			config.each |val, key| {
				if (val.val === Orderer.delete || val.val === Orderer.placeholder)
					orderer.addOrdered(key.toStr, val.val, val.con)
				else
					orderer.addOrdered(key.toStr, val, val.con)
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
		if (val === Orderer.delete || val === Orderer.placeholder)
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

internal class Contrib {
	Obj key; Obj? val; Str? con
	new make(Obj key, Obj? val, Str? con) {
		this.key = key
		this.val = val
		this.con = con
	}
	override Str toStr() {
		"[$key:$val]"
	}
	
	static Void main() {
		l:=(Str?[]) List.make(Str?#, 3)
		l.add(null)
	}
}