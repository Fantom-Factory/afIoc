
internal mixin Module {

	** Returns the service definition for the given service id
	abstract ServiceDef serviceDef(Str serviceId)
	
	** Locates the ids of all services that implement the provided service type, or whose service type is
    ** assignable to the provided service type (is a super-class or super-mixin).
	abstract Str[] findServiceIdsForType(Type serviceType)
	
	** Locates a service given a service id
	abstract Obj service(Str serviceId)
}
