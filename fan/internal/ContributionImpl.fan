
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

	override Void contributeOrdered(OrderedConfig config) {
		InjectionCtx.track("Gathering ORDERED configuration of type $config.contribType") |->| {
			sizeBefore := config.size
			InjectionUtils.callMethod(method, null, [config])
			sizeAfter := config.size
			InjectionCtx.log("Added ${sizeAfter-sizeBefore} contributions")
		}
	}

	override Void contributeMapped(MappedConfig config) {
		InjectionCtx.track("Gathering MAPPED configuration of type $config.contribType") |->| {			
			sizeBefore := config.size
			InjectionUtils.callMethod(method, null, [config])
			sizeAfter := config.size
			InjectionCtx.log("Added ${sizeAfter-sizeBefore} contributions")
		}
	}
}
