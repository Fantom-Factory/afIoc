
internal class ServiceDefImpl : ServiceDef {
	
	override const Str 	serviceId
	override const Type serviceType
	override const Bool isEagerLoad
	
			|->Obj| 	source
			Str 		description
	
	new make(|This|? f := null) {
		f?.call(this)
	}
	
	override |->Obj| createServiceBuilder() {
		source()
	}
	
	override Str toStr() {
		description
	}
}
