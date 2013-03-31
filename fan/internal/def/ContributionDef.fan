

** Contribution to a service configuration.
internal const mixin ContributionDef {
	
	** The service to be contributed to.
	abstract Str? serviceId()
		
	abstract Type? serviceType()
		
	** Contribution is optional, meaning it is not an error if the service to which the 
	** contribution is targetted does not exist.
	abstract Bool optional()
	
	** Performs the work needed to contribute into the ordered configuration.
	**
	** Config is the ordered configuration into which values should be loaded. 
	abstract Void contributeOrdered(Obj moduleInst, OrderedConfig config)

	** Performs the work needed to contribute into the mapped configuration.
	**
	** Config is the mapped configuration into which values should be loaded. 
	abstract Void contributeMapped(Obj moduleInst, MappedConfig config)
}
