
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
		dependencyProviders.eachWhile |depPro| {
			depPro.provide(proCtx, dependencyType)
		}
	}
}
