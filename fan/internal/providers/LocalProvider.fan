using afConcurrent

internal const class LocalProvider : DependencyProvider {

			private const ThreadLocalManager	localManager
	static	private const Type[]				localTypes		:= [LocalRef#, LocalList#, LocalMap#]	

	new make(ThreadLocalManager	localManager) {
		this.localManager = localManager 
	}

	override Bool canProvide(InjectionCtx ctx) {
		// IoC standards dictate that field injection should be denoted by a facet
		ctx.injectionKind.isFieldInjection
			? localTypes.contains(ctx.dependencyType.toNonNullable) && ctx.injectingIntoType != null && ctx.field.hasFacet(Inject#)
			: localTypes.contains(ctx.dependencyType.toNonNullable) && ctx.injectingIntoType != null
	}
	
	override Obj? provide(InjectionCtx ctx) {
		ctx.log("Creating ${ctx.dependencyType.name} dependency for ${ctx.injectingIntoType.qname}")
		type := ctx.dependencyType.toNonNullable
		name := ctx.injectingIntoType.qname.replace("::", ".")
		if (ctx.field != null)
			name += "." + ctx.field.name
		if (ctx.methodParam != null)
			name += "." + ctx.methodParam.name
		
		if (type == LocalRef#)
			return localManager.createRef(name)
		if (type == LocalList#)
			return localManager.createList(name)
		if (type == LocalMap#)
			return localManager.createMap(name)

		throw WtfErr("What's a {$type.qname}???")
	}
}
