
// TODO: rename -> Dependency...? -> Internal Registry?
internal const mixin ObjLocator {

	** Obtains a service via its unique service id. 
    abstract Obj trackServiceById(InjectionCtx ctx, Str serviceId)

	** Locates a service or dependency of the given type. If a service, the search takes into 
	** account inheritance of the service's defined mixin, not its *implementation*.
    abstract Obj trackDependencyByType(InjectionCtx ctx, Type dependencyType)

	** Autobuilds a class via a ctor marked with '@Inject', failing that, the ctor with the most 
	** parameters. Services and dependencies will be injected into the ctor parameters, and into 
	** fields (of all visibilities) marked with '@Inject'. 
    abstract Obj trackAutobuild(InjectionCtx ctx, Type type)

	** Injects services and dependencies into fields (of all visibilities) marked with '@Inject'.
	abstract Obj trackInjectIntoFields(InjectionCtx ctx, Obj service)	

	abstract ServiceDef? serviceDefById(Str serviceId)
	
	abstract ServiceDef? serviceDefByType(Type serviceType) 
	
	abstract Contribution[] contributionsByServiceDef(ServiceDef serviceDef)
}
