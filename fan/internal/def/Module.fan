
internal mixin Module {

	** Usually the qualified name of the Module Type 
	abstract Str moduleId() 
	
	** Returns the service definitions for the given service id
	abstract ServiceDef? serviceDefByQualifiedId(Str serviceId)

	** 'serviceId' maybe qualified or unqualified 
	abstract ServiceDef[] serviceDefsById(Str serviceId)

	** Locates the defs of all services that implement the provided service type, or whose service 
	** type is assignable to the provided service type (is a super-class or super-mixin).
    abstract ServiceDef[] serviceDefsByType(Type serviceType)

	abstract Contribution[] contributionsByServiceDef(ServiceDef serviceDef)

	abstract AdviceDef[] adviceByServiceDef(ServiceDef serviceDef)
	
	** Locates (and builds if necessary) a service given a service def
	abstract Obj? service(ServiceDef serviceDef, Bool returnReal, Bool? autobuild)

	abstract Str:ServiceDefinition serviceStats()
	
	abstract Void shutdown()

	abstract Bool hasServices()
}
