
internal const class AutobuildProvider : DependencyProvider {
	
	@Inject
	private const Registry registry
	
	new make(|This|di) { di(this) }
	
	override Bool canProvide(ProviderCtx ctx) {
		!ctx.fieldFacets.findType(Autobuild#).isEmpty
	}
	
	override Obj? provide(ProviderCtx ctx) {
		ctx.log("Found @Autobuild")
		service := ((ObjLocator) registry).trackAutobuild(ctx.dependencyType, Obj#.emptyList)
		return service
	}
}
