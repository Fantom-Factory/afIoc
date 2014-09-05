
internal const mixin Module {

	** Usually the qualified name of the Module Type 
	abstract Str moduleId() 
	
	abstract Contribution[] contributionsByServiceDef(ServiceDef serviceDef)

	abstract AdviceDef[] adviceByServiceDef(ServiceDef serviceDef)

	abstract ServiceDef[] serviceDefs()
	
	** Locates (and builds if necessary) a service given a service def
	abstract Obj? service(ServiceDef serviceDef, Bool returnReal, Bool? autobuild)

	abstract Str:ServiceDefinition serviceStats()
	
	abstract Void shutdown()
}
