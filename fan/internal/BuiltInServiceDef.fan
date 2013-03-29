
internal const class BuiltInServiceDef : ServiceDef {

	override const Str 	serviceId
	override const Type serviceType	
	
	new make(|This|? f := null) { f?.call(this)	}

	override |OpTracker, ObjLocator->Obj| createServiceBuilder() {
		throw IocErr("Can not create built in service '$serviceId'")
	}
	
	override Str toStr() {
		"'$serviceId' : Built In Service"
	}
}
