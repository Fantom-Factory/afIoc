
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
			config.add(obj)
		}
		return this
	}

	@Deprecated { msg="Use 'Configuration.set()' instead" }  
	This addOrdered(Str key, Obj? value, Str[] constraints := Str#.emptyList) {
		addConstraints(config.set(key, value), constraints)
		return this
	}

	@Deprecated { msg="Use 'Configuration.addPlaceholder()' instead" }  
	This addPlaceholder(Str id, Str[] constraints := Str#.emptyList) {
		addConstraints(config.addPlaceholder(id), constraints)
		return this
	}

	@Deprecated { msg="Use 'Configuration.overrideValue()' instead" }  
	This addOverride(Str existingId, Obj? newValue, Str[] newConstraints := Str#.emptyList, Str? newId := null) {
		addConstraints(config.overrideValue(existingId, newValue, newId), newConstraints)
		return this
	}

	@Deprecated { msg="Use 'Configuration.remove()' instead" }  
	This remove(Str existingId, Str? newId := null) {
		config.remove(existingId, newId)
		return this
	}
	
	override Str toStr() {
		config.toStr
	}
	
	private Void addConstraints(Constraints contrib, Str[] constraints) {
		constraints.each |constraint| {
			if (constraint.lower.startsWith("before")) {
				id := constraint["before".size..-1].trim
				if (id.startsWith(":") || id.startsWith("-"))
					id = id[1..-1].trim
				if (!id.isEmpty)
					contrib.before(id.lower)
			}
			if (constraint.lower.startsWith("after")) {
				id := constraint["after".size..-1].trim
				if (id.startsWith(":") || id.startsWith("-"))
					id = id[1..-1].trim
				if (!id.isEmpty)
					contrib.before(id.lower)
			}
		}
	}
}
