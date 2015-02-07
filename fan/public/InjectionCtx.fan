
** Passed to [DependencyProviders]`DependencyProvider` to give contextual injection information.
class InjectionCtx {
	
	** The type of injection.
	const InjectionKind	injectionKind
	
	** The 'Type' to be injected. This is the declared type of the field or method parameter.    
		  Type			dependencyType { internal set }

	** The object that will receive the injection. Only available for field and (non-static) method injection.  
		  Obj?			target { set { &target = it; &injectingInto = it } }
	
	** The 'Type' that will receive the injection. This is the implementation type and may be different to the 'depenencyType'. 
	** Not available during 'dependencyByType'.
	const Type?			targetType

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

	@NoDoc @Deprecated { msg="Use 'targetType' instead" }
	const Type? injectingIntoType

	@NoDoc @Deprecated { msg="Use 'target' instead" }
		  Obj? injectingInto { set { &injectingInto = it; &target = it; } }

		  @NoDoc
		  [Field:Obj?]?	ctorFieldVals { internal set }
		
	@NoDoc	// public to provide a backdoor for DependencyProviders
	new makeWithType(InjectionKind injectionKind, |This|? in := null) {
		this.fieldFacets	= Facet#.emptyList
		this.methodFacets	= Facet#.emptyList
		in?.call(this)
		this.injectionKind	= injectionKind
		this.injectingIntoType = targetType
	}

	@NoDoc // a common need, esp for efanXtra!
	new makeFromField(Obj? target, Field field, |This|? in := null) {
		this.injectionKind		= InjectionKind.fieldInjection
		this.target				= target
		this.targetType			= target?.typeof
		this.dependencyType		= field.type
		this.field				= field
		this.fieldFacets		= field.facets
		this.methodFacets		= Facet#.emptyList
		in?.call(this)
		this.injectingIntoType = targetType
	}

	@NoDoc
	new make(|This|? in := null) {
		in?.call(this)
		this.injectingIntoType = targetType
	}

	** Adds an nested operation description.
	** This provides contextual information in the event of an Err.
	** Example:
	** 
	**   ctx,track("Doing complicated stuff") |->Obj?| {
	**      return stuff()
	**   }
	Obj? track(Str description, |->Obj?| operation) {
		InjectionTracker.track(description, operation)
	}

	** Logs the message at IoC debug level.
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
		"Injecting into ${targetType?.qname}"
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

