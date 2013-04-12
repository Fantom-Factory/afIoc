
** Provides either a List or a Map, the result of config contribs.
** Not really a DependencyProvider as it's not contributed to DependencyProviderSource.
const internal class ConfigProvider : DependencyProvider {
	const ObjLocator		objLocator
	const ServiceDef 		serviceDef
	const Type? 			configType
	
	new make(InjectionCtx ctx, ServiceDef serviceDef, Method buildMethod) { 
		this.configType	= findConfigType(ctx, buildMethod)
		this.objLocator	= ctx.objLocator
		this.serviceDef	= serviceDef
	}

	override Bool canProvide(ProviderCtx ctx, Type dependencyType) {
		// BugFix: TestCtorInjection#testCorrectErrThrownWithWrongParams
		// Type#fits does not allow null
		(configType != null) && dependencyType.fits(configType)
	}

	override Obj provide(ProviderCtx proCtx, Type dependencyType) {
		ctx := proCtx.injectionCtx
		config := null
		if (configType.name == "List")
			config = OrderedConfig(ctx, serviceDef, configType)
		if (configType.name == "Map")
			config = MappedConfig(ctx, serviceDef, configType)

		objLocator.contributionsByServiceDef(serviceDef).each {
			config->contribute(ctx, it)
		}
		
		return config->getConfig
	}
	
	private Type? findConfigType(InjectionCtx ctx, Method buildMethod) {
		ctx.track("Looking for configuration parameter") |->Type?| {
			config := |->Obj?| {
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
				ctx.log("No configuration parameter found")
			else 
				ctx.log("Found $config")
			
			return config
		}			
	}
}
