
** Use in 'AppModule' classes to denote a service builder method.
** 
** See [Defining Services]`index#definingServices`
facet class Build {
	
	** If not specified, the service id is taken to be the qualified name of the returned type. 
	** Example:
	** 
	**   @Build
	**   static acme::MyService buildPenguin() { ... }
	** 
	** defines a service with an id of 'acme::MyService'.
	const Str? serviceId
	
	** Service scope defaults to 'perApplication' for const classes and 'perThread' for non-const 
	** classes.
	** 
	** If not specified on an 'override' method then the original value is left untouched.
	const ServiceScope? scope
	
	** The proxy strategy for the service. Defaults to 'ifRequired'.
	** 
	** If not specified on an 'override' method then the original value is left untouched.
	const ServiceProxy? proxy
	
	const Str? overrideRef	:= null
	
	const Bool overrideOptional	:= false
}
