using afBeanUtils::TypeCoercer

** Use to add create and override service configuration contributions. 
** 
** Every service may receive a list or ordered map of values; called its configuration.
** Any (external) module may contribute to this using in a configuration method.
** 
** The service defines the *type* of contribution by declaring a parameterised list or map in its 
** ctor or builder method. Contributions must be compatible with this type. 
** Example, the service 'SeaLions' may define a configuration map of '[Str:Penguin]' with the following ctor:
** 
** pre>
** class SeaLion {
**     new make(Str:Penguin foodGroups) {
**         ...
**     }
** }
** <pre
**
** Contribute to the 'SeaLion' service in the 'AppModule':
** 
** pre>
** const class AppModule {
**     Void defineServices(RegistryBuilder bob) {
**         bob.addService(SeaLion#)
**     }
** 
**     @Contribute { serviceType=SeaLion# }
**     Void contributeSeaLion(Configuration config) {
**         config["kevin"] = Penguin()
**     }
** } 
** <pre
**  
** Or use 'RegistryBuilder':
** 
** pre>
** bob := RegistryBuilder()
** bob.addService(
** bob.contributeToServiceType(SeaLion#) |Configuration config| {
**     config["kevin"] = Penguin()
** }
** <pre
** 
@Js
mixin Configuration {

	@NoDoc @Deprecated { msg="use 'build()' instead" }
	Obj autobuild(Type type, Obj?[]? ctorArgs := null, [Field:Obj?]? fieldVals := null) {
		scope.build(type, ctorArgs, fieldVals)
	}

	** Convenience method for `Scope.build`; builds an instance of the given 'Type' injecting in all dependencies.  
	Obj build(Type type, Obj?[]? ctorArgs := null, [Field:Obj?]? fieldVals := null) {
		scope.build(type, ctorArgs, fieldVals)
	}

	** Returns the active scope.
	abstract Scope scope()

	** Fantom Bug: `http://fantom.org/sidewalk/topic/2163#c13978`
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
	** 
	**   syntax: fantom
	**   config.set("key", value)
	** 
	**   config["key"] = value
	@Operator
	abstract Constraints set(Obj key, Obj? value)

	** Adds a value to the service configuration with optional ordering constraints.
	** 
	** Because the keys of *added* values are unknown, they cannot be overridden. 
	** For that reason it is advised to use 'set()' instead. 
	**  
	** 'value' is coerced to the service's contribution type.
	** 
	**   syntax: fantom
	** 	 config.add(value)
	abstract Constraints add(Obj value)

	** Adds a placeholder. Placeholders are empty configurations used to aid the ordering of actual values:
	** 
	** pre>
	** syntax: fantom
	** config.placeholder("end")
	** config.set("foo", val1).before("end")
	** config.set("bar", val2).after("end")
	** <pre
	** 
	** While not very useful in the same contribution method, they become very powerful when used across multiple modules and pods.
	** 
	** Placeholders do not appear in the the resulting configuration and are never seen by the end service. 
	abstract Constraints addPlaceholder(Str key)
	
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
	abstract Constraints overrideValue(Obj existingKey, Obj? newValue, Obj? newKey := null)
	
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
	abstract Void remove(Obj existingKey, Obj? newKey := null)


	** Defines a block where defined contributions are kept in the same order. 
	** The block itself may be ordered *before* and / or *after* other contributions:
	** 
	** pre>
	** syntax: fantom
	** config.inOrder { 
	**     config["b-1"] = 1
	**     config["b-2"] = 1
	**     config.addPlaceholder("separator")
	**     config["b-3"] = 1
	** }.before("c-1").after("a-1")
	** <pre
	abstract Constraints inOrder(|This| f)
}

@Js
internal class ConfigurationImpl : Configuration {
	
	internal const	Type 				contribType
	override 	  	Scope	 			scope
	private	const	Str					serviceId
	private			Int					impliedCount
	private			Str?				impliedConstraint
	private			Obj:Contrib			allConfig
	private			Obj:Contrib			modConfig
	private			Obj:Contrib			overrides
	private			Int					overrideCount
	private			TypeCoercer			typeCoercer
	private			Contrib[]?			orderedContribs

	internal new make(Scope scope, Type contribType, Str serviceId) {
		if (contribType.name != "Map" && contribType.name != "List")
			throw Err("Contributions Type is NOT a Map or a List ???")
		if (contribType.isGeneric)
			throw IocErr(ErrMsgs.contributions_configTypeIsGeneric(contribType, serviceId)) 

		this.serviceId		= serviceId
		this.contribType	= contribType
		this.scope 			= scope
		this.impliedCount	= 1
		this.allConfig		= makeMap(Obj#, Contrib#)
		this.modConfig		= makeMap(Obj#, Contrib#)
		this.overrides		= makeMap(Obj#, Contrib#)
		this.overrideCount	= 1
		this.typeCoercer	= TypeCoercer()
	}

	override Constraints set(Obj key, Obj? value) {
		key   = validateKey(key, false)
		value = validateVal(value)
		
		if (modConfig.containsKey(key))
			throw IocErr(ErrMsgs.contributions_configKeyAlreadyDefined(key.toStr, modConfig[key].val))
		if (allConfig.containsKey(key))
			throw IocErr(ErrMsgs.contributions_configKeyAlreadyDefined(key.toStr, allConfig[key].val))

		contrib := Contrib(key, value)
		modConfig[key] = contrib 
		
		if (orderedContribs != null) {
			last := orderedContribs.last
			if (last != null) {
				last.before(contrib.key)
				contrib.after(last.key)
			}
			orderedContribs.add(contrib)
		}
		
		return contrib
	}

	override Constraints add(Obj value) {
		if (keyType != Str#)
			throw IocErr(ErrMsgs.contributions_keyTypeNotKnown(keyType))

		key := "afIoc.unordered-" + impliedCount.toStr.padl(2)
		impliedCount++

		return set(key, value)
	}

	override Constraints addPlaceholder(Str key) {
		set(key, Orderer.PLACEHOLDER)
	}
	
	override Constraints overrideValue(Obj existingKey, Obj? newValue, Obj? newKey := null) {
		if (newKey == null)
			newKey = "afIoc.override-" + overrideCount.toStr.padl(2)
		overrideCount = overrideCount + 1

		newKey 		= validateKey(newKey, true)
		existingKey = validateKey(existingKey, true)
		newValue	= validateVal(newValue)

		if (overrides.containsKey(existingKey))
		 	throw IocErr(ErrMsgs.contributions_configOverrideKeyAlreadyDefined(existingKey.toStr, overrides[existingKey].key.toStr))

		if (modConfig.containsKey(newKey) || allConfig.containsKey(newKey))
		 	throw IocErr(ErrMsgs.contributions_configOverrideKeyAlreadyExists(newKey.toStr))

		if (overrides.vals.map { it.key }.contains(newKey))
		 	throw IocErr(ErrMsgs.contributions_configOverrideKeyAlreadyExists(newKey.toStr))

		contrib := Contrib(newKey, newValue)
		overrides[existingKey] = contrib
		return contrib
	}
	
	override Void remove(Obj existingKey, Obj? newKey := null) {
		overrideValue(existingKey, Orderer.DELETE, newKey)
	}

	override Constraints inOrder(|This| f) {
		orderedContribs	= Contrib[,]
		
		f(this)
		
		contraints := GroupConstraints(orderedContribs)
		orderedContribs	= null
		
		return contraints
	}

	
	// ---- Internal Methods ----------------------------------------------------------------------
	
	internal Void cleanupAfterMethod() {
		modConfig.each { it.finalise }
		modConfig.each { it.findImplied(modConfig) }
		modConfig.each |v, k| { allConfig[k] = v }
	}
	
	internal Int size() {
		allConfig.size
	}

	internal List toList() {
		contribs := orderedContributions
		config   := (Obj?[]) List.make(valueType, contribs.size)
		contribs.each { config.add(it.val) }
		return config
	}

	internal Map toMap() {
		mapType := Map#.parameterize(["K":keyType, "V":valueType])
		config  := (Obj:Obj?) Map.make(mapType) { it.ordered = true }
		
		orderedContributions.each {
			config[it.key] = it.val
		}
		return config
	}

	private Contrib[] orderedContributions() {
		keys := makeMap(keyType, keyType)
		allConfig.each |val, key| { keys[key] = key }
		
		// don't alter the class state so getConfig() may be called more than once
		config := (Obj:Contrib) this.allConfig.dup

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
			throw IocErr(ErrMsgs.contributions_overrideDoesNotExist(existingKeys, overrideKeys))
		}
		
		configKeys := config.keys
		orderer := Orderer()
		config.each |val, key| {
			value := (val.val === Orderer.DELETE || val.val === Orderer.PLACEHOLDER) ? val.val : val
			orderer.addOrdered(key, value, val.befores, val.afters)
		}

		return orderer.toOrderedList
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

		throw IocErr(ErrMsgs.contributions_configTypeMismatch("key", key.typeof, keyType))
	}

	private Obj? validateVal(Obj? val) {
		if (val === Orderer.DELETE || val === Orderer.PLACEHOLDER)
			return val

		if (val == null) {
			if (!valueType.isNullable)
				throw IocErr(ErrMsgs.contributions_configTypeMismatch("value", null, valueType))
			return val
		}

		// don't use ReflectUtils.fits() - let TypeCoercer do a proper job.
		if (val.typeof.fits(valueType))
			return val

		// empty lists and maps can always be converted
		if (!isEmptyList(val) && !isEmptyMap(val))
			if (!typeCoercer.canCoerce(val.typeof, valueType))
				throw IocErr(ErrMsgs.contributions_configTypeMismatch("value", val.typeof, valueType))

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

	private Obj:Obj? makeMap(Type keyType, Type valType) {
		mapType := Map#.parameterize(["K":keyType, "V":valType])
		return keyType.fits(Str#) ? Map.make(mapType) { caseInsensitive = true } : Map.make(mapType) { ordered = true }
	}

	@NoDoc
	override Str toStr() {
		"${contribType.name} configuration of ${contribType.signature} for '$serviceId'".replace("sys::", "")
	}	
}
