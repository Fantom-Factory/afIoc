
** (Service) -
** Contribute `DependencyProvider`s to provide your own dependencies for fields annotated with the 
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
	
	internal abstract Bool canProvideDependency(ProviderCtx proCtx, Type dependencyType)

	internal abstract Obj? provideDependency(ProviderCtx proCtx, Type dependencyType)
	
}

