
** aka UberConfig
class Contributions {
	
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
		this.config			= Utils.makeMap(Str#, Contrib#)
		this.overrides		= Utils.makeMap(Str#, Contrib#)
		this.overrideCount	= 1
		this.typeCoercer	= CachingTypeCoercer()
	}

	** A helper method that instantiates an object, injecting any dependencies. See `Registry.autobuild`.  
	Obj autobuild(Type type, Obj?[]? ctorArgs := null, [Field:Obj?]? fieldVals := null) {
		return objLocator.trackAutobuild(type, ctorArgs, fieldVals)
	}

	** A helper method to create an object proxy. Use to break circular service dependencies. See `Registry.createProxy`.  
	Obj createProxy(Type mixinType, Type? implType := null, Obj?[]? ctorArgs := null, [Field:Obj?]? fieldVals := null) {
		objLocator.trackCreateProxy(mixinType, implType, ctorArgs, fieldVals)
	}
	
	** A convenience method that returns the IoC Registry.
	Registry registry() {
		(Registry) objLocator
	}

	
	** Fantom Bug: http://fantom.org/sidewalk/topic/2163#c13978
	@Operator 
	private Obj? get(Obj key) { null }

	@Operator
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

	// like set, but don't care about it's placement
	@Operator
	This add(Obj value, Str? constraints := null) {
		if (contribType.name == "Map")
			throw Err()	// FIXME: err msg
		key := "_Unordered-" + impliedCount.toStr.padl(2)

		return set(key, value, constraints)
	}

	This placeholder(Str key, Str? constraints := null) {
		set(key, Orderer.placeholder, constraints)
	}
	
	This replace(Obj existingKey, Obj? newValue, Str? newConstraints := null, Str? newKey := null) {
		if (newKey == null)
			newKey = "_Override-" + overrideCount.toStr.padl(2)
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
	
	This remove(Obj existingKey, Str? newKey := null) {
		replace(existingKey, Orderer.delete, null, newKey)
	}


	
	// ---- Internal Methods ----------------------------------------------------------------------

	** dynamically invoked - just a reset method
	internal Void contribute(Contribution contribution) {
		// implied ordering only per contrib method
		impliedConstraint = null
		// FIXME
//		contribution.contributeOrdered(this)
	}	
	
	
	internal Int size() {
		config.size
	}

	** dynamically invoked
	internal List getConfigList() {
		contribs := orderedContribs
		return List.make(valueType, contribs.size).addAll(contribs.map { it.val })
	}

	internal Map getConfigMap() {
		mapType := Map#.parameterize(["K":keyType, "V":valueType])
		config := Map.make(mapType) { ordered = true }
		
		orderedContribs.each {
			config[it.key] = it.val
		}
		return config
	}

	private Contrib[] orderedContribs() {
		keys := Utils.makeMap(keyType, keyType)
		config.each |val, key| { keys[key] = key }
		
		// don't alter the class state so getConfig() may be called more than once
		Obj:Contrib config := this.config.dup

		InjectionTracker.track("Applying config overrides to '$serviceDef.serviceId'") |->| {
			// normalise keys -> map all keys to orig key and apply overrides
			norm := (Obj:Contrib) this.config.dup 
			found := true
			while (!norm.isEmpty && found) {
				found = false
				norm = norm.exclude |val, existingKey| {
					overrideKey := val.key
					if (keys.containsKey(existingKey)) {
						keys[overrideKey] = keys[existingKey]
						found = true
						
						InjectionTracker.log("'${overrideKey}' overrides '${existingKey}'")
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
				throw IocErr(IocMessages.contributions_overrideDoesNotExist(existingKeys, overrideKeys))
			}
		}			
			
		ordered := InjectionTracker.track("Ordering configuration contributions") |->Contrib[]| {
			orderer := Orderer()
			config.each |val, key| {
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
		if (val == Orderer.delete || val == Orderer.placeholder)
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
		"Contributions of ${contribType.signature}".replace("sys::", "")
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
}