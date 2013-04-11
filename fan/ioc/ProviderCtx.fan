
** As given to `DependencyProvider`s.
class ProviderCtx {
	
	internal InjectionCtx injectionCtx
	
	** All facets the field (to be injected) is annotated with 
	Facet[] facets

	internal new make(|This| f) { f(this) }

	** Adds an nested operation description to the 'OpTracker'. This provides contextual 
	** information in the event of an Err.
	** 
	** See `IocHelper.debugOperation`
	Obj? track(Str description, |->Obj?| operation) {
		injectionCtx.track(description, operation)
	}

	** Logs details via the 'OpTracker'.
	** 
	** See `IocHelper.debugOperation`
	Void log(Str description) {
		injectionCtx.log(description)
	}

	//	** The object the dependency will be injected into
//	Type? injectingInto

	// notes on possible injection ctx
	
//	building type
// - autobuild
// - serviceDef
// 
//injecting into instance
// - null for ctor
// 
//facets
// - null for ctor
// 
//method call
//
//
//FieldInjection
// - dependencyType
// - injectingInto Type (can't have instance 'cos we may be part of torInjectionPlan)
// - fieldFacets
// 
//CtorInjection
// - dependencyType
// - injectingInto (no instance - it's not made yet!)
// - ctorFacets
// 
//MethodInjection
// - dependencyType
// - injectingInto
// - methodFacets
// 
//abstract Bool canProvide(ProviderCtx ctx, InjectionMode , Type dependencyType, Type injectingInto, Facet[] facets)

}
