
@Js
internal const class ConfigProvider : DependencyProvider {

	override Bool canProvide(Scope currentScope, InjectionCtx ctx) {
		ctx.isFuncArgServiceConfig
	}
	
	override Obj? provide(Scope currentScope, InjectionCtx ctx) {
		// I'm happy calling internal methods here, 'cos this is an internal operation!
		scope		:= (ScopeImpl) currentScope
		serviceDef	:= scope.serviceDefById(ctx.serviceId, true)
		opStack		:= ((RegistryImpl) scope.registry).opStack 
		opStack.push("Gathering config", serviceDef.id)
		try 	return serviceDef.gatherConfiguration(currentScope, ctx.funcParam.type)
		finally	opStack.pop
	}
}
