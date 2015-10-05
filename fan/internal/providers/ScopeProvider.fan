
@Js
internal const class ScopeProvider : DependencyProvider {

	override Bool canProvide(Scope currentScope, InjectionCtx ctx) {
		if (ctx.isFieldInjection && !ctx.field.hasFacet(Inject#))
			return false

		if (ctx.isFuncInjection && ctx.isFuncArgReserved)
			return false
		
		dependencyType := ctx.field?.type ?: ctx.funcParam.type
		return dependencyType.fits(Scope#)
	}
	
	override Obj? provide(Scope currentScope, InjectionCtx ctx) {
		currentScope
	}
}
