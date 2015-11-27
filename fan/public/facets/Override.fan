
** Use in 'AppModule' classes to override a service builder.
@Js
facet class Override {
	
	** The service Id (or override Id) to be overridden. 
	** 
	** Use either this or 'serviceType', not both.
	const Str?	serviceId	:= null

	** The type of the service to be overridden.
	**  
	** Use either this or 'serviceId', not both.
	const Type?	serviceType	:= null
	
	** Override the list of scopes the service may be created in.
	const Str[]? scopes		:= null

	** Override the list of service ID aliases.
	const Str[]? aliases	:= null

	** Override the list of service types aliases.
	const Type[]? aliasTypes	:= null

	** An optional reference to this override, so others may override this override.
	** 3rd party libraries should always supply an 'overrideId'. 
	const Str? overrideId	:= null
	
	** Marks the override as optional; no Err is thrown if the service is not found. 
	** 
	** This allows you to override services that may or may not be defined in the registry.
	** (e.g. overriding services from optional 3rd party libraries.)
	const Bool optional	:= false
}
