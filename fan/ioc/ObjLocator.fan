
**
** Defines an object which can provide access to services defined within a `Registry`
** 
mixin ObjLocator {

	** Obtains a service via its unique service id. 
    abstract Obj serviceById(Str serviceId)

	** Locates a service given a service interface. A single service must implement the service
	** interface (which can be hard to guarantee). The search takes into account inheritance of the service interface
	** (not the service *implementation*), which may result in a failure due to extra matches.
    abstract Obj serviceByType(Type serviceType)

	** Autobuilds a class by finding the public constructor with the most parameters. Services and other resources or
	** dependencies will be injected into the parameters of the constructor and into private fields marked with the
	** `Inject` annotation. 
	**
	** Tracks the operation using `OperationTracker#invoke`
    abstract Obj autobuild(Str description, Type type)

}
