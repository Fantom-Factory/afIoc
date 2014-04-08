
internal const class AutobuildProvider : DependencyProvider {
	
	@Inject
	private const Registry registry

	new make(|This|di) { di(this) }

	override Bool canProvide(InjectionCtx ctx) {
		!ctx.fieldFacets.findType(Autobuild#).isEmpty
	}
	
	override Obj? provide(InjectionCtx ctx) {
		ctx.log("Found @Autobuild")
		service := ((ObjLocator) registry).trackAutobuild(ctx.dependencyType, Obj#.emptyList, null)
		return service
	}
}
