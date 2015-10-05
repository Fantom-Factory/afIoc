
** Use in 'AppModule' classes to denote a service builder method.
@Js
facet class Build {
	
	** If not specified, the service id is taken to be the qualified name of the returned type. 
	** Example:
	** 
	**   syntax: fantom
	**   @Build
	**   acme::MyService buildPenguin() { ... }
	** 
	** defines a service with an id of 'acme::MyService'.
	const Str? serviceId	:= null
	
	** A list of scopes this service may be created in.
	const Str[]? scopes		:= null

	** A list of service ID aliases.
	const Str[]? aliases	:= null

	** A list of service Type aliases.
	const Type[]? aliasTypes:= null
	
}
