
** 
** Implement to provide your own dependency resolution. Extend the capabilities of IoC!
** 
** Contribute it to the `DependencyProviderSource` service.
** 
** @since 1.1
const mixin DependencyProvider {

	** Return 'true' if the provider can provide. (!)
	abstract Bool canProvide(ProviderCtx providerCtx)

	** Return the dependency to be injected. All details of the injection to be performed is in 'providerCtx'.
	abstract Obj? provide(ProviderCtx providerCtx)
	
}
