
internal const class ThreadStashProvider : DependencyProvider {

	@Inject	private const ThreadStashManager threadStashManager

	new make(|This|di) { di(this) }

	override Bool canProvide(InjectionCtx ctx) {
		ctx.dependencyType.fits(ThreadStash#) && (ctx.injectingIntoType != null)
	}
	
	override Obj? provide(InjectionCtx ctx) {
		ctx.log("Creating ThreadStash dependency for ${ctx.injectingIntoType.qname}")
		return threadStashManager.createStash(ctx.injectingIntoType.name)
	}
}
