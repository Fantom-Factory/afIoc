
internal const class ServiceIdProvider : DependencyProvider {
	
	@Inject @ServiceId { serviceId = "registry" }
	private const RegistryImpl registry
	
	new make(|This|di) { di(this) }
	
	override Obj? provide(ProviderCtx ctx, Type dependencyType) {
		serviceIds := ctx.facets.findType(ServiceId#)
		if (serviceIds.isEmpty)
			return null
		
		serviceId := (serviceIds[0] as ServiceId).serviceId
		ctx.log("Found @ServiceId { $serviceId }")
		service := registry.trackServiceById(ctx.injectionCtx, serviceId)
		
		if (!service.typeof.fits(dependencyType))
			throw IocErr(ServiceMessages.serviceIdDoesNotFitField(serviceId, service.typeof, dependencyType))
		
		return service
	}
	
}
