
** 
** Extend the capabilities of IoC by providing your own dependency resolution.
** 
** See `DependencyProviderSource`
const mixin DependencyProvider {
	
	** Return the dependency to be injected, or 'null' if not found.
	abstract Obj? provide(ProviderCtx ctx, Type dependencyType)
	
}
