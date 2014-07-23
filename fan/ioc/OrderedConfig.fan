
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
@Deprecated { msg="Use 'Configuration' instead" }
class OrderedConfig {
	private ConfigurationImpl config

	internal new make(ConfigurationImpl config) {
		this.config = config
	}

	** A helper method that instantiates an object, injecting any dependencies. See `Registry.autobuild`.  
	Obj autobuild(Type type, Obj?[] ctorArgs := Obj#.emptyList, [Field:Obj?]? fieldVals := null) {
		config.registry.autobuild(type, ctorArgs, fieldVals)
	}

	** A helper method to create an object proxy. Use to break circular service dependencies. See `Registry.createProxy`.  
	Obj createProxy(Type mixinType, Type? implType := null, Obj?[] ctorArgs := Obj#.emptyList, [Field:Obj?]? fieldVals := null) {
		config.registry.createProxy(mixinType, implType, ctorArgs, fieldVals)
	}

	** Adds an unordered object to a service's configuration. 
	** An attempt is made to coerce the object to the contrib type.
	@Operator
	This add(Obj object) {
		config.add(object)
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
		config.set(id, value, constraints.join(", "))
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
		config.placeholder(id, constraints.join(", "))
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
		config.replace(existingId, newValue, newConstraints.join(", "), newId)
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
		config.remove(existingId, newId)
		return this
	}
}
