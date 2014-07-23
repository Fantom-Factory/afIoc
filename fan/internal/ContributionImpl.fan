
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
		config.reset
		
		InjectionTracker.track("Gathering configuration of type $config.contribType") |->| {
			sizeBefore := config.size
			
			conf := (Obj?) null
			if (method.params.first.type == Configuration#)
				conf = Configuration(config)
			if (method.params.first.type == OrderedConfig#)
				conf = OrderedConfig(config)
			if (method.params.first.type == MappedConfig#)
				conf = MappedConfig(config)
			
			InjectionUtils.callMethod(method, null, [conf])
			sizeAfter := config.size
			InjectionTracker.log("Added ${sizeAfter-sizeBefore} contributions")
		}
	}
}
