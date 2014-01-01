
** Passed into [DependencyProviders]`DependencyProvider` to give contextual injection information.
class ProviderCtx {
	
	** The type of injection.
	const InjectionType	injectionType
	
	** The 'Type' to be injected
	const Type			dependencyType

	** The object that will receive the injection. Only available for field and (non-static) method injection.  
		  Obj?			injectingInto
	** The 'Type' that will receive the injection. Not available during 'dependencyByType'.
	const Type?			injectingIntoType

	** The field to be injected. Only available for field injection. 
	const Field?		field
	** The facets of the field to be injected. Is never null, but may be empty. 
	const Facet[]		fieldFacets

	** The method to be injected. Only available for method injection. 
	const Method?		method
	** The facets of the method to be injected. Is never null, but may be empty. 
	const Facet[]		methodFacets
	** The method 'Param' to be injected. Only available for method injection. 
	const Param?		methodParam
	** The index of the method 'Param' to be injected. Only available for method injection. 
	const Int?			methodParamIndex

	internal new make(|This| f) { f(this) }

	** Adds an nested operation description to the 'OpTracker'. This provides contextual 
	** information in the event of an Err.
	** 
	** See `IocHelper.debugOperation`
	Obj? track(Str description, |->Obj?| operation) {
		InjectionTracker.track(description, operation)
	}

	** Logs details via the 'OpTracker'.
	** 
	** See `IocHelper.debugOperation`
	Void log(Str description) {
		InjectionTracker.log(description)
	}
}

** Used by `ProviderCtx` to inform 'DependencyProviders' what type of injection is occurring.
enum class InjectionType {
	
	** A direct call to 'Registry.dependencyByType()' 
	dependencyByType,
	
	** Field injection.
	fieldInjection,
	
	** Field injection via a ctor it-block.
	fieldInjectionViaItBlock,
	
	** Ctor Injection.
	ctorInjection,

	** Calling a method.
	methodInjection;
}
