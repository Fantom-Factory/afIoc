
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

	internal const	Type 			contribType
	private  const 	ServiceDef 		serviceDef
	private 	  	InjectionCtx	ctx
	private			Orderer			orderer
	private			Int				impliedCount
	private			Str[]?			impliedConstraint
	
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
		if (!object.typeof.fits(listType))
			throw IocErr(IocMessages.orderedConfigTypeMismatch(object.typeof, listType))

		if (constraints.isEmpty)
			constraints = impliedConstraint ?: Str#.emptyList
		
		orderer.addOrdered(id, object, constraints)

		// keep an implied list ordering
		impliedCount++
		impliedConstraint = ["after: $id"]
	}

//	** Overrides a contributed ordered object. The original object must exist.
//	Void addOverride(Str id, Str idToOverride, Obj object, Str[] constraints := [,]) {
//	}

	internal Void contribute(InjectionCtx ctx, Contribution contribution) {
		// implied ordering only per contrib method
		impliedConstraint = null
		contribution.contributeOrdered(ctx, this)
	}
	
	internal List getConfig() {
		ctx.track("Ordering configuration contributions") |->List| {
			contribs := orderer.order.map { it.payload }
			return List.make(listType, 10).addAll(contribs)
		}
	}
	
	private once Type listType() {
		contribType.params["V"]
	}
	
	override Str toStr() {
		"OrderedConfig of $listType"
	}
}
