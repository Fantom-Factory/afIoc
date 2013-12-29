
internal const class ServiceIdProvider : DependencyProvider {
	
	@Inject
	private const Registry registry
	
	new make(|This|di) { di(this) }
	
	override Bool canProvide(ProviderCtx ctx, Type dependencyType) {
		!ctx.fieldFacets.findType(ServiceId#).isEmpty
	}
	
	override Obj? provide(ProviderCtx ctx, Type dependencyType) {
		serviceIds := ctx.fieldFacets.findType(ServiceId#)
		if (serviceIds.size > 1)
			throw WtfErr("WTF? It's a compile error to facetate(?) a field more than once! ${ServiceId#.name} on $dependencyType.qname")
		
		serviceId := (serviceIds[0] as ServiceId).serviceId
		ctx.log("Found @ServiceId { $serviceId }")
		service := ((ObjLocator) registry).trackServiceById(serviceId)
		
		if (!service.typeof.fits(dependencyType))
			throw IocErr(IocMessages.serviceIdDoesNotFit(serviceId, service.typeof, dependencyType))
		
		return service
	}
	
}
