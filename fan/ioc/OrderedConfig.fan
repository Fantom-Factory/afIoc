
** Passed into module contribution methods to allow the method to, err, contribute!
**
** A service can *collect* contributions in three different ways:
** - As an unordered list of values
** - As an ordered list of values
** - As a map of keys and values
** 
** The service defines the *type* of contribution by declaring a parameterised list or map in its 
** ctor or builder method. Contributions must be compatible with the type.
class OrderedConfig {

	internal const	Type 				contribType
	private  const 	ServiceDef 			serviceDef
	private 	  	InjectionCtx		ctx
	private			Orderer				orderer
	private			Int					impliedCount
	private			Str[]?				impliedConstraint
	private			Str:OrderedOverride	config
	private			Str:OrderedOverride	overrides 

	
	internal new make(InjectionCtx ctx, ServiceDef serviceDef, Type contribType) {
		if (contribType.name != "List")
			throw WtfErr("Ordered Contrib Type is NOT list???")
		if (contribType.isGeneric)
			throw IocErr(IocMessages.orderedConfigTypeIsGeneric(contribType, serviceDef.serviceId)) 

		this.ctx 			= ctx
		this.serviceDef 	= serviceDef
		this.contribType	= contribType
		this.orderer		= Orderer()
		this.impliedCount	= 1
		this.overrides		= Utils.makeMap(Str#, OrderedOverride#)
		this.config			= Utils.makeMap(Str#, OrderedOverride#)
	}

	** A helper method that instantiates an object, injecting any dependencies. See `Registry.autobuild`.  
	Obj autobuild(Type type) {
		ctx.objLocator.trackAutobuild(ctx, type)
	}

	** Adds an unordered object to a service's configuration.
	Void addUnordered(Obj object) {
		id := "Unordered${impliedCount}"
		addOrdered(id, object)
	}

	** Adds all the unordered objects to a service's configuration.
	Void addUnorderedAll(Obj[] objects) {
		objects.each |obj| {
			addUnordered(obj)
		}
	}

	** Adds an ordered object to a service's contribution. Each object has a unique id (case 
	** insensitive) that is used by the constraints for ordering. Each constraint must start with 
	** the prefix 'BEFORE:' or 'AFTER:'.
	** 
	** pre>
	** config.addOrdered("Breakfast", eggs)
	** config.addOrdered("Lunch", ham, ["AFTER: breakfast", "BEFORE: dinner"])
	** config.addOrdered("Dinner", pie)
	** <pre
	** 
	** Configuration contributions are ordered across modules. 
	Void addOrdered(Str id, Obj object, Str[] constraints := Str#.emptyList) {
		object = validateVal(object)
		
		if (constraints.isEmpty)
			constraints = impliedConstraint ?: Str#.emptyList
		
		config[id] = OrderedOverride(id, object, constraints)
		
		// this orderer is throwaway, we just use to fail fast on dup key errs
		orderer.addOrdered(id, object, constraints)

		// keep an implied list ordering
		impliedCount++
		impliedConstraint = ["after: $id"]
	}

	** Overrides a contributed ordered object. The original object must exist.
	** 
	** @since 1.2
	Void addOverride(Str existingId, Str newId, Obj newObject, Str[] newConstraints := [,]) {
		newObject	= validateVal(newObject)

		if (overrides.containsKey(existingId))
		 	throw IocErr(IocMessages.configOverrideKeyAlreadyDefined(existingId.toStr, overrides[existingId].key.toStr))

//		if (config.containsKey(existingId))
//		 	throw IocErr(IocMessages.configOverrideKeyAlreadyExists(existingId.toStr))

//		if (overrides.vals.map { it.key }.contains(existingId))
//		 	throw IocErr(IocMessages.configOverrideKeyAlreadyExists(existingId.toStr))
		
		overrides[existingId] = OrderedOverride(newId, newObject, newConstraints)
	}

	internal Void contribute(InjectionCtx ctx, Contribution contribution) {
		// implied ordering only per contrib method
		impliedConstraint = null
		contribution.contributeOrdered(ctx, this)
	}

	internal List getConfig() {
		ctx.track("Applying config overrides to '$serviceDef.serviceId'") |->List| {
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
						
						ctx.log("'${overrideKey}' overrides '${existingKey}'")
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
			config.each |val| {
				orderer.addOrdered(val.key, val.val, val.con)
			}
		
			return ctx.track("Ordering configuration contributions") |->List| {
				contribs := orderer.order.map { it.payload }
				return List.make(listType, 10).addAll(contribs)
			}
		}		
	}

	private once Type listType() {
		contribType.params["V"]
	}
	
	private Obj validateVal(Obj object) {
		if (!object.typeof.fits(listType))
			throw IocErr(IocMessages.orderedConfigTypeMismatch(object.typeof, listType))
		return object
	}
	
	override Str toStr() {
		"OrderedConfig of $listType"
	}
}

internal class OrderedOverride {
	Str key; Obj val; Str[] con
	new make(Str key, Obj val, Str[] con) {
		this.key = key
		this.val = val
		this.con = con
	}
	override Str toStr() {
		"[$key:$val]"
	}
}
