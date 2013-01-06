
**
** Defines the contents of a module. 
** 
mixin ServiceDef {

	** Returns a factory func that creates the service implementation
	abstract |->Obj| createServiceBuilder()

	** Returns the service id, derived from the method name or the unqualified service interface name. Service ids must
	** be unique among *all* services in all modules. Service ids are used in a heavy handed way to support
	** ultimate disambiguation, but their primary purpose is to support service contribution methods.
	abstract Str serviceId()

	** Returns the service facet associated with this service. This is the facet exposed to the outside world.
	** In cases where the service is *not* defined in terms of a facet, this will return the actual implementation 
	** class of the service. 
	abstract Type serviceType()

//	** Returns true if the service should be eagerly loaded at Registry startup.
//	abstract Bool isEagerLoad()
	
}
