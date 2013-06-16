
internal const mixin AdviceDef {

	abstract Str serviceIdGlob()
		
	abstract Method advisorMethod()

	** if true, do not throw err on startup if this does not match any services 
	abstract Bool optional()
	
	abstract Bool matchesServiceId(Str serviceId)
}
