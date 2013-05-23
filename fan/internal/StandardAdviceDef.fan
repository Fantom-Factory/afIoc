
internal const class StandardAdviceDef : AdviceDef {
	
	override const Str		serviceIdGlob
	override const Method 	advisorMethod

	private const Regex 	globMatcher
	
	new make(|This|? f := null) { 
		f?.call(this)
		globMatcher = Regex.glob(serviceIdGlob)
	}
	
	override Bool matchesServiceId(Str serviceId) {
		globMatcher.matches(serviceId)
	}
}
