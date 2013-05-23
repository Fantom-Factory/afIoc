
**
** Defines the contents of a module. 
** 
internal const mixin ModuleDef {

	abstract Str moduleId() 
	
	** Returns the class that will be instantiated
    abstract Type moduleType()

	** Returns a map services built/provided by the module mapped by service id (case is ignored)
	abstract Str:ServiceDef serviceDefs()

	** Returns all the contribution definitions provided by this module
	abstract ContributionDef[] contributionDefs()

	** Returns all the advice definitions provided by this module
	abstract AdviceDef[] adviceDefs()
}