
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
	
	override Void contribute(Contributions contrib) {
		contrib.reset
		
		InjectionTracker.track("Gathering configuration of type $contrib.contribType") |->| {
			sizeBefore := contrib.size
			
			config := (Obj) contrib
			if (method.params.first.type == OrderedConfig#)
				config = OrderedConfig(contrib)
			if (method.params.first.type == MappedConfig#)
				config = MappedConfig(contrib)
			
			InjectionUtils.callMethod(method, null, [config])
			sizeAfter := contrib.size
			InjectionTracker.log("Added ${sizeAfter-sizeBefore} contributions")
		}
	}
}
