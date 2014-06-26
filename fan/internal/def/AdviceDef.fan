
internal const mixin AdviceDef {

	abstract Method advisorMethod()

	** if true, do not throw err on startup if this does not match any services 
	abstract Bool optional()
	
	abstract Bool matchesService(ServiceDef serviceDef)
	
	abstract Str errMsg()
}
