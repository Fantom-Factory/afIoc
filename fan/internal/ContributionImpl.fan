
internal const class ContributionImpl : Contribution {
	
	const Str?			serviceId
	const Type? 		serviceType
	const ObjLocator	objLocator
	const Method		method
	
	new make(|This|? f := null) { 
		f?.call(this)
	}	

	override ServiceDef serviceDef() {
		if (serviceId != null)
			return objLocator.serviceDefById(serviceId)
		if (serviceType != null)
			return objLocator.serviceDefByType(serviceType)
		throw WtfErr("Both serviceId & serviceType are null!?")
	}
	
	override Void contributeOrdered(InjectionCtx ctx, OrderedConfig config) {
		ctx.track("Gathering ordered configuration of type $config.contribType") |->| {			
			ctx.withConfigProvider(ContribProvider(config)) |->| {
				InjectionUtils.callMethod(ctx, method, null)
			}
		}
	}

	override Void contributeMapped(Obj moduleInst, MappedConfig config) {
		
	}	
}

internal const class ContribProvider : DependencyProvider {
	
	private const LocalStash stash		:= LocalStash(typeof)
	private const Type		type
	
	private Obj config {
		get { stash["config"] }
		set { stash["config"] = it }
	}

	new make(Obj config) {
		this.type = config.typeof
		this.config = config
	}
	
	override Obj? provide(Obj objCtx, Type dependencyType, Facet[] facets := Obj#.emptyList) {
		(dependencyType == type) ? config : null
	}
}