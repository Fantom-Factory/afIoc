
** Contribution to a service configuration.
internal const class ContributionDef {
	
	const Str?		serviceId
	const Type?		serviceType
	const Bool 		optional
	const Method 	method
	
	new make(|This| f) { f(this) }
}
