
** 
** Implement to provide your own dependency resolution. Extend the capabilities of IoC!
** 
** Contribute it to the `DependencyProviderSource` service.
** 
** @since 1.1
const mixin DependencyProvider {

	** Return 'true' if the provider can provide. (!)
	abstract Bool canProvide(InjectionCtx injectionCtx)

	** Return the dependency to be injected. All details of the injection to be performed is in 'InjectionCtx'.
	abstract Obj? provide(InjectionCtx injectionCtx)
	
}
