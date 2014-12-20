
** Use in services to inject classes that have not been defined as a service. 
** Instances are created via [Registry.autobuild()]`Registry#autobuild`.
** 
** @since 2.0.0
facet class Autobuild {
	
	** If 'true' a proxy is created.
	const Bool createProxy

	** The implementation type to create.
	const Type? implType
	
	** Arguments to pass to the implementation ctor.
	const Obj?[]? ctorArgs
	
	** Sets to set via an it-block ctor argument.
	const [Field:Obj?]? fieldVals
}
