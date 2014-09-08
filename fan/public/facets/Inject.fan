
// Facet Inheritance not applicable with fields - see http://fantom.org/sidewalk/topic/2186
// see TestInjectFacetInheritance
// @FacetMeta { inherited = true } 

** Use in services to inject dependencies and services.
**  - Place on a field to mark it for field injection
**  - Place on a ctor to mark it for use by autobuilding / service creation
facet class Inject { 
	
	** Specifies the (qualified) id of the service to inject. 
	**  
	** Use when a service mixin has multiple implementations.
	const Str? serviceId
	
	** If 'true' and the dependency / service does not exist then injection fails silently without causing an Err.
	** 
	** Useful when injecting services from (optional) 3rd party libraries. 
	** 
	** Defaults to 'false'.
	const Bool optional		:= false
}
