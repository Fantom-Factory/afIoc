
const mixin DependencyProviderSource {
	
	abstract Obj? provideDependency(ProviderCtx proCtx)
	
}


internal const class DependencyProviderSourceImpl : DependencyProviderSource {
	
	private const DependencyProvider[] dependencyProviders
	
	new make(DependencyProvider[] dependencyProviders) {
		this.dependencyProviders = dependencyProviders.toImmutable
	}
	
	override Obj? provideDependency(ProviderCtx proCtx) {
		dependencyProviders.eachWhile |depPro| {
			// TODO: FIXME:
			return null
//			depPro.provide(ctx, dependencyType, facets)
		}
	}
}
