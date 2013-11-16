
internal mixin Module {

	** Usually the qualified name of the Module Type 
	abstract Str moduleId() 
	
	** Returns the service definition for the given service id
	abstract ServiceDef? serviceDef(Str serviceId)

	** Locates the defs of all services that implement the provided service type, or whose service 
	** type is assignable to the provided service type (is a super-class or super-mixin).
    abstract ServiceDef[] serviceDefsByType(Type serviceType)

	abstract Contribution[] contributionsByServiceDef(ServiceDef serviceDef)

	abstract AdviceDef[] adviceByServiceDef(ServiceDef serviceDef)
	
	** Locates (and builds if necessary) a service given a service id
	abstract Obj? service(InjectionCtx ctx, Str serviceId, Bool returnReal)

	abstract Str:ServiceStat serviceStats()
	
	abstract Void clear()
}
