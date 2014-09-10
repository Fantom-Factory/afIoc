
** Use in 'AppModule' classes to denote a service override method.
** 
** See [Defining Services]`index#definingServices`
facet class Override {
	
	** The service Id (or override Id) to be overridden. 
	** 
	** Use either this or 'serviceType', not both.
	const Str?	serviceId	:= null

	** The type of the service to be overridden.
	**  
	** Use either this or 'serviceId', not both.
	const Type?	serviceType	:= null
	
	** If specified this will override the service's scope setting.
	const ServiceScope? scope	:= null
	
	** If specified this will override the service's proxy setting.
	const ServiceProxy? proxy	:= null
	
	** An optional reference to this override, so others may override this override.
	** 3rd party libraries should always supply an 'overrideId'. 
	const Str? overrideId	:= null
	
	** Marks the override as optional; no Err is thrown if the service is not found. 
	** 
	** This allows you to override services that may or may not be defined in the registry.
	** (e.g. overriding services from optional 3rd party libraries.)
	const Bool optional	:= false
}
