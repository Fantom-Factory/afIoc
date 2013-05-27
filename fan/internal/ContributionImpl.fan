
internal const class ContributionImpl : Contribution {
	
	const Str?			serviceId
	const Type? 		serviceType
	const ObjLocator	objLocator
	const Method		method
	
	new make(|This|? f := null) { 
		f?.call(this)
	}	

	override ServiceDef? serviceDef() {
		if (serviceId != null)
			return objLocator.serviceDefById(serviceId)
		if (serviceType != null)
			return objLocator.serviceDefByType(serviceType)
		throw WtfErr("Both serviceId & serviceType are null!?")
	}

	override Void contributeOrdered(InjectionCtx ctx, OrderedConfig config) {
		ctx.track("Gathering ORDERED configuration of type $config.contribType") |->| {
			sizeBefore := config.size
			InjectionUtils.callMethod(ctx, method, null, [config])
			sizeAfter := config.size
			ctx.log("Added ${sizeAfter-sizeBefore} contributions")
		}
	}

	override Void contributeMapped(InjectionCtx ctx, MappedConfig config) {
		ctx.track("Gathering MAPPED configuration of type $config.contribType") |->| {			
			sizeBefore := config.size
			InjectionUtils.callMethod(ctx, method, null, [config])
			sizeAfter := config.size
			ctx.log("Added ${sizeAfter-sizeBefore} contributions")
		}
	}
}
