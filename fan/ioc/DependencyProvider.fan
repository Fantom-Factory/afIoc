
** 
** Extend the capabilities of IoC by providing your own dependency resolution.
** 
** See `DependencyProviderSource`
const mixin DependencyProvider {

	** Return 'true' if the provider can provide. (!)
	abstract Bool canProvide(ProviderCtx ctx, Type dependencyType)

	** Return the dependency to be injected
	abstract Obj provide(ProviderCtx ctx, Type dependencyType)
	
}
