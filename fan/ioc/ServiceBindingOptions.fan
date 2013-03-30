
**
** Allows additional options for a service to be specified, overriding hard coded defaults.
** 
mixin ServiceBindingOptions {
	
	** Sets a specific id for the service, rather than the default (from the service type). This is 
	** useful when multiple services implement the same mixin, since service ids must be unique.
	abstract This withId(Str id)

	** Uses the the simple (unqualified) class name of the implementation class as the service id.
	abstract This withSimpleId()

	** Sets the service scope. Note only 'const' classes can be defined as `ScopeDef.perApplication`.
	** (Tip: 'const' services can subclass `ConcurrentState` for easy access to modifiable state.)
	abstract This withScope(ScopeDef scope)

//	** Turns eager loading on for this service.
//	abstract This eagerLoad();

}
