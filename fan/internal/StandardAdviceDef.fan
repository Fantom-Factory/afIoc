
internal const class StandardAdviceDef : AdviceDef {
	
			 const Str		serviceIdGlob
			 const Type?	serviceType
	override const Method 	advisorMethod
	override const Bool 	optional

	private const Regex 	globMatcher
	
	new make(|This|? f := null) { 
		f?.call(this)
		globMatcher = Regex.glob(serviceIdGlob)
	}
	
	override Bool matchesService(ServiceDef serviceDef) {
		(serviceType != null) 
			? serviceDef.serviceType.fits(serviceType)
			: globMatcher.matches(serviceDef.serviceId)
	}
	
	override Str errMsg() {
		(serviceType != null) 
			? "serviceType of ${serviceType.qname}"
			: "serviceId glob '${serviceIdGlob}'"
	}
}
