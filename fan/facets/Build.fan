
** Use in a module class to denote a service builder method.
** 
** See [Defining Services]`index#definingServices`
facet class Build {
	
	** If not specified, the service id is taken to be the name of the buider method, minus the 
	** build prefix. Example:
	** 
	**   @Build
	**   static MyService buildPenguin() { ... }
	** 
	** defines a service with an id of 'penguin'.
	const Str? 			serviceId	:= null
	
	** Service scope defaults to 'perApplication' for const classes and 'perThread' for non-const 
	** classes.
	const ServiceScope? scope		:= null
}
