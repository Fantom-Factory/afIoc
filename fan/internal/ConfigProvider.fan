
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

	Bool canProvide(ProviderCtx ctx, Type dependencyType) {
		// BugFix: TestCtorInjection#testCorrectErrThrownWithWrongParams
		// Type#fits does not allow null
		(configType != null) && dependencyType.fits(configType)
	}

	Obj? provide(ProviderCtx proCtx, Type dependencyType) {
		objLocator := InjectionCtx.peek.objLocator
		config := null
		if (configType.name == "List")
			config = OrderedConfig(objLocator, serviceDef, configType)
		if (configType.name == "Map")
			config = MappedConfig(objLocator, serviceDef, configType)

		objLocator.contributionsByServiceDef(serviceDef).each {
			config->contribute(it)
		}
		
		return config->getConfig
	}

	private Type? findConfigType(Method buildMethod) {
		InjectionCtx.track("Looking for configuration parameter") |->Type?| {
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
				InjectionCtx.log("No configuration parameter found")
			else 
				InjectionCtx.log("Found $config.signature")
			
			return config
		}			
	}
}
