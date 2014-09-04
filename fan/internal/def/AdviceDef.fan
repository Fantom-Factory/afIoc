
internal const class AdviceDef {
	
	const Str		serviceIdGlob
	const Type?		serviceType
	const Method 	advisorMethod
	const Bool	 	optional

	private const Regex 	globMatcher
	
	new make(|This|? f := null) { 
		f?.call(this)
		globMatcher = Regex.glob(serviceIdGlob)
	}
	
	Bool matchesService(ServiceDef serviceDef) {
		(serviceType != null) 
			? serviceDef.serviceType.fits(serviceType)
			: globMatcher.matches(serviceDef.serviceId)
	}
	
	Str errMsg() {
		(serviceType != null) 
			? "serviceType of ${serviceType.qname}"
			: "serviceId glob '${serviceIdGlob}'"
	}
}