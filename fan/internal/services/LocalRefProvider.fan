using afConcurrent::LocalRef

internal const class LocalRefProvider : DependencyProvider {

	@Inject	private const ThreadLocalManager localManager

	new make(|This|di) { di(this) }

	override Bool canProvide(InjectionCtx ctx) {
		LocalRef# == ctx.dependencyType.toNonNullable && (ctx.injectingIntoType != null)
	}
	
	override Obj? provide(InjectionCtx ctx) {
		ctx.log("Creating LocalRef dependency for ${ctx.injectingIntoType.qname}")
		name := ctx.injectingIntoType.qname.replace("::", ".")
		if (ctx.field != null)
			name += "." + ctx.field.name
		if (ctx.methodParam != null)
			name += "." + ctx.methodParam.name
		return localManager.createRef(name)
	}
}
