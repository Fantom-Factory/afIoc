
internal const class ConfigProvider : DependencyProvider {

	override Bool canProvide(InjectionCtx ctx) {
		if (ctx.injectionKind == InjectionKind.ctorInjection || ctx.injectionKind == InjectionKind.methodInjection)
			if (ctx.methodParamIndex == 0)
				if (ctx.dependencyType.name == "List" || ctx.dependencyType.name == "Map") {
					configType := InjectionTracker.peekServiceDef?.configType
					if (configType != null && ctx.dependencyType.fits(configType))
						return true
				}
		return false
	}
	
	override Obj? provide(InjectionCtx ctx) {
		ctx.log("Found Configuration '$ctx.dependencyType.signature'")
		return InjectionTracker.peekServiceDef.gatherConfiguration
	}	
}
