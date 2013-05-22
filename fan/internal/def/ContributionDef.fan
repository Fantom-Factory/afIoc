
** Contribution to a service configuration.
internal const mixin ContributionDef {
	
	** The service to be contributed to.
	abstract Str? serviceId()
		
	abstract Type? serviceType()

	abstract Method method()
			
	** Contribution is optional, meaning it is not an error if the service to which the 
	** contribution is targetted does not exist.
	abstract Bool optional()

}
