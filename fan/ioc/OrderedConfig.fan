
** Passed into module contribution methods to allow the method to, err, contribute!
**
** A service can *collect* contributions in three different ways:
** - As an unordered list of values
** - As an ordered list of values
** - As a map of keys and values
** 
** The service defines the *type* of contribution by declaring a parameterised list or map in its 
** ctor or builder method. Contributions must be compatible with the type.
** 
** @see `TypeCoercer`
class OrderedConfig {

	internal const	Type 				contribType
	private  const 	ServiceDef 			serviceDef
	private 	  	ObjLocator 			objLocator
	private			Orderer				orderer
	private			Int					impliedCount
	private			Str[]?				impliedConstraint
	private			Int					overrideCount
	private			Str:OrderedOverride	config
	private			Str:OrderedOverride	overrides
	private			TypeCoercer			typeCoercer

	internal new make(ObjLocator objLocator, ServiceDef serviceDef, Type contribType) {
		if (contribType.name != "List")
			throw WtfErr("Ordered Contrib Type is NOT list???")
		if (contribType.isGeneric)
			throw IocErr(IocMessages.orderedConfigTypeIsGeneric(contribType, serviceDef.serviceId)) 

		this.objLocator 	= objLocator
		this.serviceDef 	= serviceDef
		this.contribType	= contribType
		this.orderer		= Orderer()
		this.impliedCount	= 1
		this.overrideCount	= 1
		this.overrides		= Utils.makeMap(Str#, OrderedOverride#)
		this.config			= Utils.makeMap(Str#, OrderedOverride#)
		this.typeCoercer	= TypeCoercer()
	}

	** A helper method that instantiates an object, injecting any dependencies. See `Registry.autobuild`.  
	Obj autobuild(Type type, Obj?[] ctorArgs := Obj#.emptyList, [Field:Obj?]? fieldVals := null) {
		return objLocator.trackAutobuild(type, ctorArgs, fieldVals)
	}

	** A helper method to create an object proxy. Use to break circular service dependencies. See `Registry.createProxy`.  
	Obj createProxy(Type mixinType, Type? implType := null, Obj?[] ctorArgs := Obj#.emptyList, [Field:Obj?]? fieldVals := null) {
		objLocator.trackCreateProxy(mixinType, implType, ctorArgs, fieldVals)
	}

	** Adds an unordered object to a service's configuration. 
	** An attempt is made to coerce the object to the contrib type.
	@Operator
	This add(Obj object) {
		id := "Unordered${impliedCount}"
		addOrdered(id, object)
		return this
	}

	** Adds all the unordered objects to a service's configuration.
	** An attempt is made to coerce the objects to the contrib type.
	This addAll(Obj[] objects) {
		objects.each |obj| {
			add(obj)
		}
		return this
	}

	** Adds an ordered object to a service's contribution. Each object has a unique id (case 
	** insensitive) that is used by the constraints for ordering. Each constraint must start with 
	** the prefix 'BEFORE:' or 'AFTER:'.
	** 
	** pre>
	**   config.addOrdered("Breakfast", eggs)
	**   config.addOrdered("Dinner", pie)
	**   config.addOrdered("Lunch", ham, ["AFTER: breakfast", "BEFORE: dinner"])
	** <pre
	** 
	** Configuration contributions are ordered across modules. 
	** 
	** An attempt is made to coerce the object to the contrib type.
	This addOrdered(Str id, Obj? value, Str[] constraints := Str#.emptyList) {
		value = validateVal(value)
		
		if (constraints.isEmpty) {
			constraints = impliedConstraint ?: constraints
			
			// keep an implied ordering for anything that doesn't have its own constraints
			impliedCount++
			impliedConstraint = ["after: $id"]
		}
		
		config[id] = OrderedOverride(id, value, constraints)
		
		// this orderer is throwaway, we just use to fail fast on dup key errs
		orderer.addOrdered(id, value, constraints)

		return this
	}

	** Adds a placeholder. Placeholders are empty configurations used to aid ordering.
	** 
	** pre>
	**   config.addPlaceholder("End")
	**   config.addOrdered("Wot", ever, ["BEFORE: end"])
	**   config.addOrdered("Last", last, ["AFTER: end"])
	** <pre
	** 
	** Placeholders do not appear in the the resulting ordered list. 
	** 
	** @since 1.2.0
	This addPlaceholder(Str id, Str[] constraints := Str#.emptyList) {
		addOrdered(id, Orderer.placeholder, constraints)
		return this
	}

	** Overrides a contributed ordered object. The original object must exist.
	** An attempt is made to coerce the override to the contrib type.
	** 
	** Note: Unordered configurations can not be overridden.
	** 
	** Note: If a 'newId' is supplied then this override itself may be overridden by other 
	** contributions. 3rd party libraries, when overriding, should always supply a 'newId'.     
	** 
	** @since 1.2.0
	This addOverride(Str existingId, Obj? newValue, Str[] newConstraints := Str#.emptyList, Str? newId := null) {
		newValue = validateVal(newValue)

		if (overrides.containsKey(existingId))
		 	throw IocErr(IocMessages.configOverrideKeyAlreadyDefined(existingId.toStr, overrides[existingId].key.toStr))

		if (newId == null)
			newId = "Override${overrideCount}"

		overrideCount = overrideCount + 1
		overrides[existingId] = OrderedOverride(newId, newValue, newConstraints)
		return this
	}

	** A special kind of override whereby, should this be the last override applied, the value is 
	** removed from the configuration.
	** 
	** Note: If a 'newId' is supplied then this override itself may be overridden by other 
	** contributions. 3rd party libraries, when overriding, should always supply a 'newId'.
	** 
	** @since 1.4.0
	This remove(Str existingId, Str? newId := null) {
		addOverride(existingId, Orderer.delete, Str#.emptyList, newId)
	}

	** dynamically invoked
	internal Void contribute(Contribution contribution) {
		// implied ordering only per contrib method
		impliedConstraint = null
		contribution.contributeOrdered(this)
	}

	** dynamically invoked
	internal List getConfig() {
		InjectionTracker.track("Applying config overrides to '$serviceDef.serviceId'") |->List| {
			keys := Utils.makeMap(Str#, Str#)
			config.each |val, key| { keys[key] = key }
			
			// don't alter the class state so getConfig() may be called more than once
			Str:OrderedOverride config := this.config.dup 

			// normalise keys -> map all keys to orig key and apply overrides
			Str:OrderedOverride norm := overrides.dup
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
			
			orderer := Orderer()
			config.each |val, key| {
				orderer.addOrdered(key, val.val, val.con)
			}
		
			return InjectionTracker.track("Ordering configuration contributions") |->List| {
				contribs := orderer.toOrderedList
				return List.make(listType, contribs.size).addAll(contribs)
			}
		}		
	}

	internal Int size() {
		config.size
	}

	private once Type listType() {
		contribType.params["V"]
	}
	
	private Obj? validateVal(Obj? object) {
		if (object == Orderer.delete || object == Orderer.placeholder)
			return object
		
		if (object == null) {
			if (!listType.isNullable)
				throw IocErr(IocMessages.orderedConfigTypeMismatch(null, listType))
			return object
		}

		if (object.typeof.fits(listType))
			return object

		if (typeCoercer.canCoerce(object.typeof, listType))
			return typeCoercer.coerce(object, listType)

		throw IocErr(IocMessages.orderedConfigTypeMismatch(object.typeof, listType))
	}
	
	override Str toStr() {
		"OrderedConfig of $listType"
	}	
}

internal class OrderedOverride {
	Str key; Obj? val; Str[] con
	new make(Str key, Obj? val, Str[] con) {
		this.key = key
		this.val = val
		this.con = con
	}
	override Str toStr() {
		"[$key:$val]"
	}
}
