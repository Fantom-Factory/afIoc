
@Js
internal const class ConfigProvider : DependencyProvider {

	override Bool canProvide(Scope currentScope, InjectionCtx ctx) {
		ctx.isFuncArgServiceConfig
	}
	
	override Obj? provide(Scope currentScope, InjectionCtx ctx) {
		// I'm happy calling internal methods here, 'cos this is an internal operation!
		scope		:= (ScopeImpl) currentScope
		serviceDef	:= scope.serviceDefById(ctx.serviceId, true)
		return serviceDef.gatherConfiguration(currentScope, ctx.funcParam.type)
	}
}
