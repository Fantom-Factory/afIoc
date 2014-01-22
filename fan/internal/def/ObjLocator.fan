
** An internal mixin used to decouple RegistryImpl 
internal const mixin ObjLocator {

	** Obtains a service via its unique service id. 
    abstract Obj trackServiceById(Str serviceId)

	** Locates a service or dependency of the given type. If a service, the search takes into 
	** account inheritance of the service's defined mixin, not its *implementation*.
    abstract Obj? trackDependencyByType(Type dependencyType, Bool checked)

	** Autobuilds a class via a ctor marked with '@Inject', failing that, the ctor with the most 
	** parameters. Services and dependencies will be injected into the ctor parameters, and into 
	** fields (of all visibilities) marked with '@Inject'. 
    abstract Obj trackAutobuild(Type type, Obj?[] initParams)

	abstract Obj trackCreateProxy(Type mixinType, Type? implType, Obj?[] ctorArgs)

	** Injects services and dependencies into fields (of all visibilities) marked with '@Inject'.
	abstract Obj trackInjectIntoFields(Obj service)	

	abstract Obj? trackCallMethod(Method method, Obj? instance, Obj?[] providedMethodArgs)	

	abstract ServiceDef? serviceDefById(Str serviceId)
	
	abstract ServiceDef? serviceDefByType(Type serviceType) 
	
	abstract Obj getService(ServiceDef serviceDef, Bool returnReal)

	abstract Contribution[] contributionsByServiceDef(ServiceDef serviceDef)

	abstract AdviceDef[] adviceByServiceDef(ServiceDef serviceDef)
	
	abstract Str:Obj? options()
	
	abstract Str:ServiceStat stats()
	
	abstract Void logServiceCreation(Type log, Str msg)
}
