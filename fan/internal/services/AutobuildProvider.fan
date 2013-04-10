
internal const class AutobuildProvider : DependencyProvider {
	
	@Inject @ServiceId { serviceId = "registry" }
	private const RegistryImpl registry
	
	new make(|This|di) { di(this) }
	
	override Obj? provide(ProviderCtx ctx, Type dependencyType) {
		serviceIds := ctx.facets.findType(Autobuild#)
		if (serviceIds.isEmpty)
			return null
		
		ctx.log("Found @Autobuild")
		service := registry.trackAutobuild(ctx.injectionCtx, dependencyType)
		return service
	}
	
}
