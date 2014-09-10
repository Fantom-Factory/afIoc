
** Passed to [DependencyProviders]`DependencyProvider` to give contextual injection information.
class InjectionCtx {
	
	** The type of injection.
	const InjectionKind	injectionKind
	
	** The 'Type' to be injected
		  Type			dependencyType { internal set }

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
		  Param?		methodParam  { internal set }
	** The index of the method 'Param' to be injected. Only available for method injection. 
		  Int?			methodParamIndex  { internal set }

		  @NoDoc
		  [Field:Obj?]?	ctorFieldVals { internal set }
	
	internal new makeWithType(InjectionKind injectionKind, |This|? in := null) {
		this.fieldFacets	= Facet#.emptyList
		this.methodFacets	= Facet#.emptyList
		in?.call(this)
		this.injectionKind	= injectionKind
	}

	private new make(|This|? in := null) {
		in?.call(this)
	}

	** Adds an nested operation description to the 'OpTracker'. This provides contextual 
	** information in the event of an Err.
	Obj? track(Str description, |->Obj?| operation) {
		InjectionTracker.track(description, operation)
	}

	** Logs details via the 'OpTracker'. The message logged at IoC debug level.
	Void log(Str msg) {
		InjectionTracker.log(msg)
	}
	
	internal Bool isForConfigType(Type? configType) {
		(injectionKind == InjectionKind.ctorInjection || injectionKind == InjectionKind.methodInjection) && 
		methodParamIndex == 0 && 
		configType != null && 
		dependencyType.fits(configType)
	}
	
	@NoDoc
	override Str toStr() {
		"Injecting into ${injectingIntoType.qname}"
	}
}

** As returned by `InjectionCtx` to inform 'DependencyProviders' what kind of injection is occurring.
enum class InjectionKind {
	
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
	
	** Returns true if a field injection (of any kind) is taking place
	Bool isFieldInjection() {
		this == fieldInjection || this == fieldInjectionViaItBlock
	}
}

