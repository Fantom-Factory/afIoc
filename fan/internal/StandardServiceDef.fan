
internal const class StandardServiceDef : ServiceDef {
	
	override const Str 		serviceId
	override const Type		serviceType
	override const ScopeDef	scope
	
	const |OpTracker, ObjLocator->Obj| 	source
	const Str	description
	
	new make(|This|? f := null) { f?.call(this)	}
	
	override |OpTracker, ObjLocator->Obj| createServiceBuilder() {
		source
	}
	
	override Str toStr() {
		description
	}
}
