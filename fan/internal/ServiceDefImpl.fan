
internal const class ServiceDefImpl : ServiceDef {
	
	override 
	const Str 	serviceId
	
	override 
	const Type	serviceType
	
	const |OpTracker, ObjLocator->Obj| 	source
	const Str	description
	
	new make(|This|? f := null) {
		f?.call(this)
	}
	
	override |OpTracker, ObjLocator->Obj| createServiceBuilder() {
		source
	}
	
	override Str toStr() {
		description
	}
}
