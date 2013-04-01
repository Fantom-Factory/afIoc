
@NoDoc
const mixin DependencyProvider {
	
	abstract Obj? provide(Type dependencyType, Facet[] facets := Obj#.emptyList)
	
}
