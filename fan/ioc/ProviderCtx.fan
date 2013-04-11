
** As given to `DependencyProvider`s.
class ProviderCtx {
	
	internal InjectionCtx injectionCtx
	
	** All facets the field (to be injected) is annotated with. 
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
}
