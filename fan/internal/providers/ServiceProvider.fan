
@Js
internal const class ServiceProvider : DependencyProvider {

	override Bool canProvide(Scope currentScope, InjectionCtx ctx) {
		if (ctx.isFieldInjection)
			// all field service injection should be denoted by a facet
			return ctx.field.hasFacet(Inject#)

		if (ctx.isFuncInjection)
			return ctx.isFuncArgReserved.not && ((ScopeImpl) currentScope).serviceDefByType(ctx.funcParam.type, false) != null 
		
		return false
	}
	
	override Obj? provide(Scope currentScope, InjectionCtx ctx) {
		if (ctx.isFieldInjection) {
			inject	:= (Inject) Slot#.method("facet").callOn(ctx.field, [Inject#])	// Stoopid F4

			if (inject.id != null)
				return currentScope.serviceById(inject.id, inject.optional.not)

			serviceType := inject.type ?: ctx.field.type
			return currentScope.serviceByType(serviceType, inject.optional.not)
		}

		if (ctx.isFuncInjection) {
			return currentScope.serviceByType(ctx.funcParam.type, true)
		}

		throw Err("WTF? Injection type not catered for")
	}
}
