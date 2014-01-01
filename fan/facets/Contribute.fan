
** Use in 'AppModule' classes to denote a service contribution method. The service to be contributed to 
** is derived from either the serviceId, serviceType, or the method name. 
** 
** Either 'serviceId' or 'serviceType' should be defined, not both. Or as a last resort, if neither 
** are given, the service id is derived from the method name, removing the prefix "contribute". 
** Though this latter approach is not re-factor safe.
facet class Contribute {

	** The id of the service to be configured. 
	const Str?	serviceId	:= null

	** The type of the service to be configured. 
	const Type?	serviceType	:= null

	** Marks the contribution as optional; no Err is thrown if the service is not found. 
	** 
	** This allows you to contribute to services that may or may not be defined in the registry.
	** (e.g. contributing to optional 3rd party library)
	const Bool	optional	:= false
}
