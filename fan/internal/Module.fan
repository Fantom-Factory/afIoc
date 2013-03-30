
internal mixin Module {

	** Usually the qualified name of the Module Type 
	abstract Str moduleId() 
	
	** Returns the service definition for the given service id
	abstract ServiceDef? serviceDef(Str serviceId)

	** Locates (and builds if necessary) a service given a service id
	abstract Obj? service(OpTracker tracker, Str serviceId)

	** Locates the ids of all services that implement the provided service type, or whose service type is
    ** assignable to the provided service type (is a super-class or super-mixin).
    abstract Str[] findServiceIdsForType(Type serviceType)
	
	abstract Void clear()
}
