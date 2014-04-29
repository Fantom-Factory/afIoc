using afConcurrent::LocalMap

internal const class LocalMapProvider : DependencyProvider {

	@Inject	private const ThreadLocalManager localManager

	new make(|This|di) { di(this) }

	override Bool canProvide(InjectionCtx ctx) {
		LocalMap# == ctx.dependencyType.toNonNullable && (ctx.injectingIntoType != null)
	}
	
	override Obj? provide(InjectionCtx ctx) {
		ctx.log("Creating LocalMap dependency for ${ctx.injectingIntoType.qname}")
		name := ctx.injectingIntoType.name
		if (ctx.field != null)
			name += "." + ctx.field.name
		if (ctx.methodParam != null)
			name += "." + ctx.methodParam.name
		return localManager.createMap(name)
	}
}
