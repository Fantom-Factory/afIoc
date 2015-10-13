
** Use in classes to denote a field that should be dependency injected.
** 
** It is the intention that '@Inject' be (re)used as a general purpose facet by many dependency providers in IoC 
** and by custom libraries.
** Hence support for the attributes 'id', 'type', and 'optional' is entirely dependent on the individual dependency provider.
** 
** Core IoC dependency providers use the '@Inject' facet to:
** 
**  - inject IoC services
**  - inject Log instances
**  - mark ctors to use for autobuilding / service creation.
** 
@Js
facet class Inject {

	** When injecting services, 'id' denotes the qualified ID of the service to inject. (optional)
	** 
	** When injecting 'Log' instances, 'id' denotes the log name. (optional)
	const Str? id		:= null
	
	** When injecting services, 'type' is used to look up the service - which may be different 
	** (or more specific) than the field type. (optional)
	const Type? type	:= null
	
	** If 'true' and the dependency / service does not exist then injection should fail silently 
	** without causing an Err.
	const Bool optional	:= false

}
