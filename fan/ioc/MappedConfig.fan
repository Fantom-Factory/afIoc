
@NoDoc @Deprecated { msg="Use 'Configuration' instead" }
class MappedConfig {
	private ConfigurationImpl config

	internal new make(ConfigurationImpl config) {
		this.config = config
	}

	@Deprecated { msg="Use 'Configuration.autobuild()' instead" }  
	Obj autobuild(Type type, Obj?[] ctorArgs := Obj#.emptyList, [Field:Obj?]? fieldVals := null) {
		config.registry.autobuild(type, ctorArgs, fieldVals)
	}

	@Deprecated { msg="Use 'Configuration.registry.createProxy()' instead" }  
	Obj createProxy(Type mixinType, Type? implType := null, Obj?[] ctorArgs := Obj#.emptyList, [Field:Obj?]? fieldVals := null) {
		config.registry.createProxy(mixinType, implType, ctorArgs, fieldVals)
	}

	@Operator 
	private Obj? get(Obj key) { null }

	@Operator
	@Deprecated { msg="Use 'Configuration.set()' instead" }  
	This set(Obj key, Obj? val) {
		config.set(key, val)
		return this
	}

	@Deprecated { msg="Use 'objects.each |v, k| { Configuration.set(k, v) }' instead" }  
	This setAll(Obj:Obj? objects) {
		objects.each |val, key| {
			config.set(key, val)
		}
		return this
	}
	
	@Deprecated { msg="Use 'Configuration.overrideValue(existingKey, newValue, newKey)' instead" }  
	This setOverride(Obj existingKey, Obj? newValue, Obj? newKey := null) {
		config.overrideValue(existingKey, newValue, newKey)
		return this
	}

	@Deprecated { msg="Use 'Configuration.remove()' instead" }  
	This remove(Obj existingKey, Obj? newKey := null) {
		config.remove(existingKey, newKey)
		return this
	}
	
	override Str toStr() {
		config.toStr
	}
}
