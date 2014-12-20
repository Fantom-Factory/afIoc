
** Implement to provide your own dependency resolution. Extend the capabilities of IoC!
** 
** Contribute 'DependencyProvider' instances to the 'DependencyProviders' service.
** 
** pre>
** @Contribute { serviceType=DependencyProviders# }
** static Void contributeDependencyProviders(Configuration config) {
**     config["myProvider"] = MyProvider()
** }
** <pre
** 
** Note that due to 'DependencyProviders' being instantiated before the Registry is fully loaded, 'DependencyProviders' should *not* be proxied.
** 
** Because service injection is a 'catch-all' provider and throws an Err if a matching service is not found, should you 
** create a 'DependencyProvider' that re-uses the '@Inject' facet, you should add it *before* the service provider:
** 
** pre>
** @Contribute { serviceType=DependencyProviders# }
** internal static Void contributeDependencyProviders(Configuration config) {
**     myProvider := config.autobuild(MyProvider#)
**     config.set("acme.myProvider", myProvider).before("afIoc.serviceProvider")
** }
** <pre 
** @since 1.1
const mixin DependencyProvider {

	** Return 'true' if the provider can provide. (!)
	** 
	** This method exists to allow 'provide()' to return 'null'.
	abstract Bool canProvide(InjectionCtx injectionCtx)

	** Return the dependency to be injected. All details of the injection to be performed is in 'InjectionCtx'.
	abstract Obj? provide(InjectionCtx injectionCtx)
	
}
