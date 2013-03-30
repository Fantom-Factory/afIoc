
// TODO: rename -> Dependency...?
internal const mixin ObjLocator {

	** Obtains a service via its unique service id. 
    abstract Obj trackServiceById(OpTracker tracker, Str serviceId)

	** Locates a service or dependency of the given type. If a service, the search takes into 
	** account inheritance of the service's defined mixin, not its *implementation*.
    abstract Obj trackDependencyByType(OpTracker tracker, Type serviceType)

	** Autobuilds a class via a ctor marked with '@Inject', failing that, the ctor with the most 
	** parameters. Services and dependencies will be injected into the ctor parameters, and into 
	** fields (of all visibilities) marked with '@Inject'. 
    abstract Obj trackAutobuild(OpTracker tracker, Type type)

	** Injects services and dependencies into fields (of all visibilities) marked with '@Inject'.
	abstract Obj trackInjectIntoFields(OpTracker tracker, Obj service)	

}
