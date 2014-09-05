
internal const mixin Module {

	** Usually the qualified name of the Module Type 
	abstract Str moduleId() 
	
	abstract Contribution[] contributionsByServiceDef(ServiceDef serviceDef)

	abstract AdviceDef[] adviceByServiceDef(ServiceDef serviceDef)

	abstract ServiceDef[] serviceDefs()
	
	abstract Void shutdown()
}
