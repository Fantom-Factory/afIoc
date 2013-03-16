
**
** Meta info that defines a service 
** 
internal mixin ServiceDef {

	** Returns a factory func that creates the service implementation
	abstract |OpTracker, ObjLocator->Obj| createServiceBuilder()

	** Returns the service id, which is usually the unqualified service type name.
	abstract Str serviceId()

	** Returns the service type, either the mixin or implementation type depending on how it was 
	** defined.
	abstract Type serviceType()

//	** Returns true if the service should be eagerly loaded at Registry startup.
//	abstract Bool isEagerLoad()
	
}
