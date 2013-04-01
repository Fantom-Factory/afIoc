
@NoDoc
const mixin DependencyProvider {
	
	** ctx is currently undefined. Assume it is 'null'.
	abstract Obj? provide(Obj ctx, Type dependencyType, Facet[] facets := Obj#.emptyList)
	
}
