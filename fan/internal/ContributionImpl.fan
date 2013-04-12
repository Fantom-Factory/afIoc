
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
			sizeBefore := config.getConfig.size
			ctx.withProvider(ContribProvider(config)) |->| {
				InjectionUtils.callMethod(ctx, method, null)
			}
			sizeAfter := config.getConfig.size
			ctx.log("Added ${sizeAfter-sizeBefore} contributions")
		}
	}

	override Void contributeMapped(InjectionCtx ctx, MappedConfig config) {
		ctx.track("Gathering MAPPED configuration of type $config.contribType") |->| {			
			sizeBefore := config.getConfig.size
			ctx.withProvider(ContribProvider(config)) |->| {
				InjectionUtils.callMethod(ctx, method, null)
			}
			sizeAfter := config.getConfig.size
			ctx.log("Added ${sizeAfter-sizeBefore} contributions")
		}
	}
}

** Provides either an OrderedConfig or MappedConfig. 
** Not really a DependencyProvider as it's not contributed to DependencyProviderSource
internal const class ContribProvider : DependencyProvider {
	
	private const LocalStash stash	:= LocalStash(typeof)
	private const Type		type
	
	private Obj config {
		get { stash["config"] }
		set { stash["config"] = it }
	}

	new make(Obj config) {
		this.type = config.typeof
		this.config = config
	}
	
	override Bool canProvide(ProviderCtx ctx, Type dependencyType) {
		return dependencyType == type
	}

	override Obj provide(ProviderCtx proCtx, Type dependencyType) {
		config
	}
}