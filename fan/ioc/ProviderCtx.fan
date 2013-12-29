
// TODO: fandoc - aims to give you as much contextual info as possible.
** As given to `DependencyProvider`s.
class ProviderCtx {
	
	** All facets the field (to be injected) is annotated with 
//	const Facet[] facets

	// TODO: fandoc
	const InjectionType	injectionType
	const Type			dependencyType
	
		  Obj?			injectingInto
	const Type?			injectingIntoType

	const Field?		field
	const Facet[]		fieldFacets

	const Method?		method
	const Facet[]		methodFacets
	const Param?		methodParam
	const Int?			methodParamIndex
	
	internal new make(|This| f) { f(this) }

	** Adds an nested operation description to the 'OpTracker'. This provides contextual 
	** information in the event of an Err.
	** 
	** See `IocHelper.debugOperation`
	Obj? track(Str description, |->Obj?| operation) {
		InjectionCtx.track(description, operation)
	}

	** Logs details via the 'OpTracker'.
	** 
	** See `IocHelper.debugOperation`
	Void log(Str description) {
		InjectionCtx.log(description)
	}
}

enum class InjectionType {
	dependencyByType,
	fieldInjection,
	fieldInjectionViaItBlock,
	ctorInjection,
	methodInjection;	
}
