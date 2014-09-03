
** 
** Returned from 'ServiceBinder.bind()'; lets you specify additional service options. Use to override defaults.
** 
mixin ServiceBindingOptions {

	** Sets a specific id for the service, rather than the default (the qualified name of the service type / mixin).  
	** Required when you have multiple implementations of the same mixin, since service ids must be unique.
	abstract This withId(Str id)

	** Uses the the simple (unqualified) class name of the implementation class as the service id.
	abstract This withSimpleId()

	** Sets the service scope. Note only 'const' classes can be defined as 
	** `ServiceScope.perApplication`.
	** 
	** (Tip: See [afConcurrent]`http://www.fantomfactory.org/pods/afConcurrent` for sharing data between threads.)
	abstract This withScope(ServiceScope scope)

	** Disables the creation of a service proxy. Only applicable if the service is fronted by a mixin. 
	abstract This withoutProxy()
}
