
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
@Deprecated { msg="Use 'Configuration' instead" }
class MappedConfig {
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

	** Fantom Bug: http://fantom.org/sidewalk/topic/2163#c13978
	@Operator 
	private Obj? get(Obj key) { null }

	** Adds a keyed object to the service's configuration.
	** An attempt is made to coerce the key / value to the map type.
	@Operator
	This set(Obj key, Obj? val) {
		config.set(key, val)
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
		config.replace(existingKey, newValue, null, newKey)
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
		config.remove(existingKey, newKey)
		return this
	}
}
