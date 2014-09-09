
internal const class ConfigProvider : DependencyProvider {

	override Bool canProvide(InjectionCtx ctx) {
		ctx.isForConfigType(InjectionTracker.peekServiceDef?.configType)
	}
	
	override Obj? provide(InjectionCtx ctx) {
		ctx.log("Found Configuration '$ctx.dependencyType.signature'")
		return InjectionTracker.peekServiceDef.gatherConfiguration
	}
}
