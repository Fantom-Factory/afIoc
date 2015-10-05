
@Js
internal class ContribDef {
	const Type		moduleId
	const Str?		serviceId
	const Type?		serviceType
	const Bool 		optional
	const Method?	method2
	const Unsafe	configFuncRef
	
	|Configuration|	configFunc() { configFuncRef.val }
	
	new make(|This| f) { f(this) }
	
	** Match in the same way scope.resoveByXxx() does
	Bool matches(SrvDef srvDef) {
		if (serviceId != null)
			return srvDef.matchesId(serviceId)
		if (serviceType != null)
			return srvDef.matchesType(serviceType)
		throw Err("WTF! Both serviceId & serviceType are null!?")
	}
	
	Str srvId() {
		if (serviceId != null)
			return serviceId
		if (serviceType != null)
			return serviceType.qname
		throw Err("WTF! Both serviceId & serviceType are null!?")
	}
	
	override Str toStr() { serviceId }
}
