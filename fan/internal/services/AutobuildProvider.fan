
internal const class AutobuildProvider : DependencyProvider {

	@Inject	private const Registry	registry

	new make(|This|di) { di(this) }

	override Bool canProvide(InjectionCtx ctx) {
		ctx.field != null && ctx.field.hasFacet(Autobuild#) 
	}
	
	override Obj? provide(InjectionCtx ctx) {
		ctx.log("Autobuilding ${ctx.field.type} from @Autobuild")

		autobuild := (Autobuild) Slot#.method("facet").callOn(ctx.field, [Autobuild#])	// Stoopid F4

		if (autobuild.createProxy)
			return registry.createProxy(ctx.field.type, autobuild.implType, autobuild.ctorArgs, autobuild.fieldVals)

		return registry.autobuild(autobuild.implType ?: ctx.field.type, autobuild.ctorArgs, autobuild.fieldVals)
	}
}
