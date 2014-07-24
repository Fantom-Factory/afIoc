
@NoDoc @Deprecated { msg="Use 'Configuration' instead" }
class OrderedConfig {
	private ConfigurationImpl config

	internal new make(ConfigurationImpl config) {
		this.config = config
	}

	@Deprecated { msg="Use 'Configuration.autobuild()' instead" }  
	Obj autobuild(Type type, Obj?[] ctorArgs := Obj#.emptyList, [Field:Obj?]? fieldVals := null) {
		config.registry.autobuild(type, ctorArgs, fieldVals)
	}

	@Deprecated { msg="Use 'Configuration.createProxy()' instead" }  
	Obj createProxy(Type mixinType, Type? implType := null, Obj?[] ctorArgs := Obj#.emptyList, [Field:Obj?]? fieldVals := null) {
		config.registry.createProxy(mixinType, implType, ctorArgs, fieldVals)
	}

	@Deprecated { msg="Use 'Configuration.add()' instead" }  
	@Operator
	This add(Obj object) {
		config.add(object)
		return this
	}

	@Deprecated { msg="Use 'objects.each |v| { Configuration.add(v) }' instead" }  
	This addAll(Obj[] objects) {
		objects.each |obj| {
			add(obj)
		}
		return this
	}

	@Deprecated { msg="Use 'Configuration.set()' instead" }  
	This addOrdered(Str id, Obj? value, Str[] constraints := Str#.emptyList) {
		config.set(id, value, constraints.join(", "))
		return this
	}

	@Deprecated { msg="Use 'Configuration.addPlaceholder()' instead" }  
	This addPlaceholder(Str id, Str[] constraints := Str#.emptyList) {
		config.addPlaceholder(id, constraints.join(", "))
		return this
	}

	@Deprecated { msg="Use 'Configuration.replace()' instead" }  
	This addOverride(Str existingId, Obj? newValue, Str[] newConstraints := Str#.emptyList, Str? newId := null) {
		config.overrideValue(existingId, newValue, newConstraints.join(", "), newId)
		return this
	}

	@Deprecated { msg="Use 'Configuration.remove()' instead" }  
	This remove(Str existingId, Str? newId := null) {
		config.remove(existingId, newId)
		return this
	}
}
