
internal const class StandardContributionDef : ContributionDef {
	
	override const Str?		serviceId
	override const Type?	serviceType
	override const Bool 	optional
	override const Method 	method
	
	new make(|This|? f := null) { 
		f?.call(this)
	}
	
}
