
const mixin DependencyProvider {
	
	abstract Obj? provide(ProviderCtx ctx, Type dependencyType, Facet[] facets := Obj#.emptyList)
	
}
