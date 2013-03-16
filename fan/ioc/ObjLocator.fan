
**
** Defines an object which can provide access to services defined within a `Registry`
** 
mixin ObjLocator {

	** Obtains a service via its unique service id. 
    abstract Obj serviceById(Str serviceId)

	** Locates a service of the given type. The search takes into account inheritance of the 
	** service mixin, not the service *implementation*.
    abstract Obj serviceByType(Type serviceType)

	** Autobuilds a class via a ctor marked with '@Inject', failing that, the ctor with the most 
	** parameters. Services and dependencies will be injected into the ctor parameters, and into 
	** fields (of all visibilities) marked with '@Inject'. 
    abstract Obj autobuild(Type type)

	** Injects services and dependencies into fields (of all visibilities) marked with '@Inject'.
	abstract Obj injectIntoFields(Obj service)
}
