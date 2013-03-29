
**
** Defines the contents of a module. 
** 
internal const mixin ModuleDef {

	** Returns a map services built/provided by the module mapped by service id (case is ignored)
	abstract Str:ServiceDef serviceDefs()

//	** Returns all the contribution definitions built/provided by this module.
//	abstract ContributionDef[] contributionDefs()

	** Returns the class that will be instantiated. 
    abstract Type moduleType()

	** Returns the name used to create a Logger instance. This is typically the module type name.
	abstract Str loggerName()
}