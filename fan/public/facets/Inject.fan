
// Facet Inheritance not applicable with fields - see http://fantom.org/sidewalk/topic/2186
// see TestInjectFacetInheritance
// @FacetMeta { inherited = true } 

** Use in services to inject other services and dependencies.
** 
** It is the intention that '@Inject' be (re)used a general purpose facet for many [Dependency Providers]`DependencyProvider`, both within and outside the IoC library itself.
** 
** With that in mind, support for the facet attributes 'id', 'type' and 'optional' is entirely dependent on the individual dependency providers.
** 
** Within IoC the '@Inject' facet is used to:
**  - inject IoC services,
**  - inject 'Log' instances,
**  - inject 'LocalRef', 'LocalList' and 'LocalMap' instances,
**  - mark ctors to use for autobuilding / service creation.
** 
facet class Inject { 
	
	** Usage within IoC is optional:
	**  - Service injection: the (qualified) id of the service to inject (use when the same mixin has multiple implementations)
	**  - 'Log' injection: the name of the log to inject 
	**  - 'LocalRef' injection: the name used to store the local ref.
	const Str? id
	
	** Usage within IoC is optional:
	**  - 'LocalRef' injection: the List / Map type. 
	const Type? type
	
	** If 'true' and the dependency / service does not exist then injection should fail silently without causing an Err.
	**
	** Within IoC 'optional' is only used when injecting services.
	** Useful when injecting services from (optional) 3rd party libraries. 
	** 
	** Defaults to 'false'.
	const Bool optional		:= false
}
