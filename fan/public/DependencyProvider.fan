
** Implement to provide your own dependency resolution. Extend the capabilities of IoC!
** 
** Provide your own dependencies for fields annotated with the '@Inject' facet. 
** Typically you would augment '@Inject' with your own facet to provide injection meta. 
** See [@ServiceId]`ServiceId` and [@Autobuild]`Autobuild` for built-in examples. 
** 
** Contribute 'DependencyProvider' instances to the 'DependencyProviders' service.
** 
** pre>
** @Contribute { serviceType=DependencyProviders# }
** static Void contributeDependencyProviders(Configuration conf) {
**   conf["myProvider"] = conf.autobuild(MyProvider#)
** }
** <pre
** 
** Due to 'DependencyProviders' being instantiated before the Registry is fully loaded, 'DependencyProviders' should not be proxied.
** 
** @since 1.1
const mixin DependencyProvider {

	** Return 'true' if the provider can provide. (!)
	** 
	** This method exists to allow 'provide()' to return 'null'.
	abstract Bool canProvide(InjectionCtx injectionCtx)

	** Return the dependency to be injected. All details of the injection to be performed is in 'InjectionCtx'.
	abstract Obj? provide(InjectionCtx injectionCtx)
	
}
