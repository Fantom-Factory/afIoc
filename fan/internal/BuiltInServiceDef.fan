
internal const class BuiltInServiceDef : ServiceDef {

	override const Str 			moduleId
	override const Str 			serviceId
	override const Type 		serviceType	
	override const ServiceScope scope
	
	new make(|This|? f := null) { f?.call(this)	}

	override |InjectionCtx->Obj| createServiceBuilder() {
		throw IocErr("Can not create built in service '$serviceId'")
	}
	
	override Str toStr() {
		"'$serviceId' : Built In Service"
	}
}
