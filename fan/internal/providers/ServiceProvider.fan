
internal const class ServiceProvider : DependencyProvider {
	private const ObjLocator objLocator

	new make(Registry registry) { 
		this.objLocator = (ObjLocator) registry 
	}

	override Bool canProvide(InjectionCtx ctx) {
		// IoC standards dictate that field injection should be denoted by a facet
		ctx.injectionKind.isFieldInjection
			? ctx.field.hasFacet(Inject#)
			: objLocator.typeMatchesService(ctx.dependencyType)
	}
	
	override Obj? provide(InjectionCtx ctx) {
		serviceId := (Str?) null 
		optional  := false 

		if (ctx.injectionKind.isFieldInjection) {
			inject		:= (Inject) Slot#.method("facet").callOn(ctx.field, [Inject#])	// Stoopid F4
			serviceId	= inject.serviceId
			optional	= inject.optional
		}

		if (serviceId != null) {
			ctx.log("Field has @Inject { serviceId=\"${serviceId}\" }")

			// this throws Err if not optional and service not found
			service := objLocator.trackServiceById(serviceId, !optional)
			if (service == null && optional) {
				ctx.log("Field has @Inject { optional=true }")
				ctx.log("Service not found - failing silently...")
				return null
			}			

			ctx.log("Found Service '${serviceId}'")
			return service
		}

		serviceDef := objLocator.serviceDefByType(ctx.dependencyType)
		if (serviceDef == null) {
			if (optional) {
				ctx.log("Field has @Inject { optional=true }")
				ctx.log("Service not found - failing silently...")
				return null
			}
			// for when looking for an @Inject field
			throw IocErr(IocMessages.serviceTypeNotFound(ctx.dependencyType))
		}

		ctx.log("Found Service '$serviceDef.serviceId'")
		return serviceDef.getService
	}
}