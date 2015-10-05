
@Js	// if someone wants their own log provider, they can remove this one and provide their own
internal const class LogProvider : DependencyProvider {

	override Bool canProvide(Scope currentScope, InjectionCtx ctx) {
		if (ctx.targetType == null)
			return false

		if (ctx.isFieldInjection && !ctx.field.hasFacet(Inject#))
			return false

		if (ctx.isFuncInjection && ctx.isFuncArgReserved)
			return false
		
		dependencyType := ctx.field?.type ?: ctx.funcParam.type
		return dependencyType.fits(Log#)
	}
	
	override Obj? provide(Scope currentScope, InjectionCtx ctx) {
		logId := ctx.targetType.pod.name
		if (ctx.isFieldInjection) {
			inject := (Inject) Slot#.method("facet").callOn(ctx.field, [Inject#])	// Stoopid F4
			if (inject.id != null)
				logId = inject.id
		}

		return Log.get(logId)
	}
}
