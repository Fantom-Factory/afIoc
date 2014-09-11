
// Facet Inheritance not applicable with fields - see http://fantom.org/sidewalk/topic/2186
// see TestInjectFacetInheritance
// @FacetMeta { inherited = true } 

** Use in services to inject services and other dependencies.
** 
** It is the intention that '@Inject' be used a general purpose facet for many [Dependency Providers]`DependencyProvider`.
** Within IoC it is used to:
**  - inject 'Log' instances,
**  - inject 'LocalRef', 'LocalList' and 'LocalMap' instances,
**  - inject IoC services,
**  - mark ctors to use for autobuilding / service creation.
** 
facet class Inject { 
	
	** Specifies a (qualified) id of the dependency / service to inject. 
	**  
	** When injecting services, use when the same mixin has multiple implementations.
	const Str? id
	
	** If 'true' and the dependency / service does not exist then injection fails silently without causing an Err.
	** 
	** Useful when injecting services from (optional) 3rd party libraries. 
	** 
	** Defaults to 'false'.
	const Bool optional		:= false
}
