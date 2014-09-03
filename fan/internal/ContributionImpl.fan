
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
	
	override Void contribute(ConfigurationImpl config) {
		InjectionTracker.track("Gathering configuration of type $config.contribType") |->| {
			sizeBefore := config.size
			
			InjectionUtils.callMethod(method, null, [Configuration(config)])
			
			config.cleanupAfterModule
			sizeAfter := config.size
			InjectionTracker.log("Added ${sizeAfter-sizeBefore} contributions")
		}
	}
}
