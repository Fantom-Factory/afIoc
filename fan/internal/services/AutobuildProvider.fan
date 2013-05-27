
internal const class AutobuildProvider : DependencyProvider {
	
	@Inject
	private const Registry registry
	
	new make(|This|di) { di(this) }
	
	override Bool canProvide(ProviderCtx ctx, Type dependencyType) {
		!ctx.facets.findType(Autobuild#).isEmpty
	}
	
	override Obj provide(ProviderCtx ctx, Type dependencyType) {
		ctx.log("Found @Autobuild")
		service := ((ObjLocator) registry).trackAutobuild(ctx.injectionCtx, dependencyType, Obj#.emptyList)
		return service
	}
}
