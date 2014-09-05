
** Provides either a List or a Map, the result of config contribs.
const internal class ConfigProvider {
	const ObjLocator		objLocator
	const ServiceDef 		serviceDef
	const Type? 			configType
	
	new make(ObjLocator objLocator, ServiceDef serviceDef, Method buildMethod) { 
		this.configType	= findConfigType(buildMethod)
		this.objLocator	= objLocator
		this.serviceDef	= serviceDef
	}

	Bool canProvide(Type dependencyType) {
		// BugFix: TestCtorInjection#testCorrectErrThrownWithWrongParams
		// Type#fits does not allow null
		(configType != null) && dependencyType.fits(configType)
	}

	Obj? provide(Type dependencyType) {
		objLocator := InjectionTracker.peek.objLocator

		config := ConfigurationImpl(objLocator, serviceDef, configType)
		serviceDef.contribute(config)
		
		if (configType.name == "List")
			return config.toList
		if (configType.name == "Map")
			return config.toMap

		throw WtfErr("${configType.name} is neither a List nor a Map")
	}

	private Type? findConfigType(Method buildMethod) {
		InjectionTracker.track("Looking for configuration parameter") |->Type?| {
			config := |->Type?| {
				if (buildMethod.params.isEmpty)
					return null
				
				// Config HAS to be the first param
				paramType := buildMethod.params[0].type
				if (paramType.name == "List")
					return paramType
				if (paramType.name == "Map")
					return paramType
				return null
			}()
			
			if (config == null)
				InjectionTracker.log("No configuration parameter found")
			else 
				InjectionTracker.log("Found $config.signature")
			
			return config
		}			
	}
}
