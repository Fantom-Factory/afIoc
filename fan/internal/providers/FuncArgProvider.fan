
@Js
internal const class FuncArgProvider : DependencyProvider {

	override Bool canProvide(Scope currentScope, InjectionCtx ctx) {
		ctx.isFuncArgProvided
	}
	
	override Obj? provide(Scope currentScope, InjectionCtx ctx) {
		ctx.funcArgs[ctx.funcArgIndex]
	}
}
