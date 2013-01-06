
**
** Allows additional options for a service to be specified, overriding hard coded defaults.
** 
mixin ServiceBindingOptions {
	
	** Sets a specific id for the service, rather than the default (from the service type). This is useful when multiple services 
	** implement the same mixin, since service ids must be unique.
	abstract This withId(Str id)

	** Uses the the simple (unqualified) class name of the implementation class as the id of the service.
	abstract This withSimpleId()

//	** Turns eager loading on for this service.
//	abstract This eagerLoad();

}
