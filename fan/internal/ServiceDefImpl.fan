
internal class ServiceDefImpl : ServiceDef {
	
	override const Str 	serviceId
	override const Type serviceType
	
	|OpTracker, ObjLocator->Obj| 	source
			Str 		description
	
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
