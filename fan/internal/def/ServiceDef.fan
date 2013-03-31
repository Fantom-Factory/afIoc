
**
** Meta info that defines a service 
** 
internal const mixin ServiceDef {

	** Returns a factory func that creates the service implementation
	abstract |InjectionCtx->Obj| createServiceBuilder()

	** Returns the service id, which is usually the unqualified service type name.
	abstract Str serviceId()

	** Returns the id of the module this service was defined in
	abstract Str moduleId()
	
	** Returns the service type, either the mixin or implementation type depending on how it was 
	** defined.
	abstract Type serviceType()

	abstract ServiceScope scope()
	
	abstract Type? configType()

	
//	** Returns true if the service should be eagerly loaded at Registry startup.
//	abstract Bool isEagerLoad()
	
}
