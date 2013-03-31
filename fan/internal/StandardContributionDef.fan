
internal const class StandardContributionDef : ContributionDef {
	
	override const Str?		serviceId
	override const Type?	serviceType
	override const Bool 	optional
			 const Method 	method
	
	new make(|This|? f := null) { 
		f?.call(this)
	}
	
	override Void contributeOrdered(Obj moduleInst, OrderedConfig config) {
		
	}

	override Void contributeMapped(Obj moduleInst, MappedConfig config) {
		
	}
	
}
