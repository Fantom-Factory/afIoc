
internal const mixin AdviceDef {

	abstract Str serviceIdGlob()
		
	abstract Method advisorMethod()
	
	abstract Bool matchesServiceId(Str serviceId)
}
