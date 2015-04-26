
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
** Note that service injection is the last resort 'catch-all' provider and throws an Err if a matching service is not found.
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
