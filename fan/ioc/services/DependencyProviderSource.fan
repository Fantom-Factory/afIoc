
** (Service) -
** Contribute your `DependencyProvider` implementations to this. 
** Provide your own dependencies for fields annotated with the 
** '@Inject' facet. Typically you would augment '@Inject' with your own facet to provide injection 
** meta. See [@ServiceId]`ServiceId` and [@Autobuild]`Autobuild` for builtin examples. 
** 
** pre>
** @Contribute
** static Void contributeDependencyProviderSource(OrderedConfig conf) {
**   serviceIdProvider := conf.autobuild(ServiceIdProvider#)
**   config.add(serviceIdProvider)
** }
** <pre
** 
** @since 1.1
** 
** @uses OrderedConfig of `DependencyProvider`
const mixin DependencyProviderSource {
	
	internal abstract Bool canProvideDependency(InjectionCtx injectionCtx)

	internal abstract Obj? provideDependency(InjectionCtx injectionCtx)
}


** @since 1.1.0
internal const class DependencyProviderSourceImpl : DependencyProviderSource {
	private const DependencyProvider[] dependencyProviders

	new make(DependencyProvider[] dependencyProviders, Registry registry) {
		this.dependencyProviders = dependencyProviders.toImmutable
		
		// eager load all dependency providers else recursion err (app hangs) when creating DPs 
		// with lazy services
		ctx := InjectionCtx(InjectionType.dependencyByType) { it.dependencyType = Void# }
		dependencyProviders.each { it.canProvide(ctx) }
	}

	override Bool canProvideDependency(InjectionCtx ctx) {
		dependencyProviders.any |provider->Bool| {
			// providers can't provide themselves!
			if (ctx.dependencyType.fits(provider.typeof))
				return false
			return provider.canProvide(ctx) 
		}		
	}

	override Obj? provideDependency(InjectionCtx ctx) {
		dps := dependencyProviders.findAll { it.canProvide(ctx) }

		if (dps.isEmpty)
			return null
		
		if (dps.size > 1)
			throw IocErr(IocMessages.onlyOneDependencyProviderAllowed(ctx.dependencyType, dps.map { it.typeof }))
		
		dependency := dps[0].provide(ctx)
		
		if (dependency == null) {
			if (!ctx.dependencyType.isNullable )
				throw IocErr(IocMessages.dependencyDoesNotFit(dependency.typeof, ctx.dependencyType))
		} else {
			if (!dependency.typeof.fits(ctx.dependencyType))
				throw IocErr(IocMessages.dependencyDoesNotFit(dependency.typeof, ctx.dependencyType))
		}

		return dependency
	}
}
