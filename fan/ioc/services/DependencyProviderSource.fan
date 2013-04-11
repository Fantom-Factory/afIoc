
**
** Contribute `DependencyProvider`s to provide your own dependencies for fields annotated with the 
** '@Inject' facet. Typically you would augment '@Inject' with your own facet to provide injection 
** meta. See [@ServiceId]`ServiceId` and [@Autobuild]`Autobuild` for builtin examples. 
** 
** pre>
** @Contribute
** static Void contributeDependencyProviderSource(OrderedConfig config) {
**   serviceIdProvider := config.autobuild(ServiceIdProvider#)
**   config.addUnordered(serviceIdProvider)
** }
** <pre
** 
const mixin DependencyProviderSource {
	
	internal abstract Obj? provideDependency(ProviderCtx proCtx, Type dependencyType)
	
}

internal const class DependencyProviderSourceImpl : DependencyProviderSource {
	private const DependencyProvider[] dependencyProviders

	new make(DependencyProvider[] dependencyProviders) {
		this.dependencyProviders = dependencyProviders.toImmutable
	}

	override Obj? provideDependency(ProviderCtx proCtx, Type dependencyType) {
		dps := dependencyProviders.findAll { it.canProvide(proCtx, dependencyType) }

		if (dps.isEmpty)
			return null
		
		if (dps.size > 1)
			throw IocErr(ServiceMessages.onlyOneDependencyProviderAllowed(dependencyType, dps.map { it.typeof }))
		
		dependency := dps[0].provide(proCtx, dependencyType)
		
		if (!dependency.typeof.fits(dependencyType))
			throw IocErr(ServiceMessages.dependencyDoesNotFit(dependency.typeof, dependencyType))

		return dependency
	}
}
