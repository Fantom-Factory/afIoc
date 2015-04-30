
internal const class ServiceProvider : DependencyProvider {
	private const ObjLocator objLocator

	new make(Registry registry) { 
		this.objLocator = (ObjLocator) registry 
	}

	override Bool canProvide(InjectionCtx ctx) {
		// IoC standards dictate that field injection should be denoted by a facet
		if (ctx.injectionKind.isFieldInjection && !ctx.field.hasFacet(Inject#))
			return false

		// we should always be able to inject an @Inject field - it's an error if we can't
		if (ctx.injectionKind.isFieldInjection)
			return true

		serviceDef := objLocator.serviceDefByType(ctx.dependencyType)
		if (serviceDef != null)
			return true
		
		if (ctx.injectionKind.isMethodInjection && ctx.dependencyType.isNullable)
			// we don't inject default values
			return !ctx.methodParam.hasDefault
			
		return false
	}
	
	override Obj? provide(InjectionCtx ctx) {
		serviceId := (Str?) null 
		optional  := false 

		if (ctx.injectionKind.isFieldInjection) {
			inject		:= (Inject) Slot#.method("facet").callOn(ctx.field, [Inject#])	// Stoopid F4
			serviceId	= inject.id
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
			
			if (ctx.injectionKind.isMethodInjection && ctx.dependencyType.isNullable) {
				ctx.log("Method / ctor param is nullable")
				ctx.log("Service not found - failing silently...")
				return null				
			}
			
			// we should always be able to inject an @Inject field - it's an error if we can't
			throw IocErr(IocMessages.dependencyNotFound(ctx.dependencyType))
		}

		ctx.log("Found Service '$serviceDef.serviceId'")
		return serviceDef.getService
	}
}
