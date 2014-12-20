
** Contribution to a service configuration.
internal const class ContributionDef {
	
	const Str?		serviceId
	const Type?		serviceType
	const Bool 		optional
	const Method 	method
	
	new make(|This| f) { f(this) }
	
	Bool matchesSvrDef(SrvDef svrDef) {
		if (serviceId != null)
			return svrDef.matchesId(serviceId)
		if (serviceType != null)
			return svrDef.matchesType(serviceType)
		throw WtfErr("Both serviceId & serviceType are null!?")
	}
	
	Str srvId() {
		if (serviceId != null)
			return serviceId
		if (serviceType != null)
			return serviceType.qname
		throw WtfErr("Both serviceId & serviceType are null!?")
	}
	
	override Str toStr() { srvId }
}
