
**
** Used to update the status of services defined by the `ServiceActivityScoreboard`.
** 
internal class ServiceActivityTracker : ServiceActivityScoreboard {
	
	private Str:MutableServiceActivity serviceIdToServiceStatus := [:]

	override ServiceActivity[] serviceActivity() {
		serviceIdToServiceStatus.vals.ro
	}

	Void define(ServiceDef serviceDef, ServiceStatus initialStatus) {
		serviceIdToServiceStatus[serviceDef.serviceId] = MutableServiceActivity() {
			it.serviceId	 = serviceDef.serviceId
			it.serviceType	 = serviceDef.serviceType
			it.status		 = initialStatus
		}
	}

	Void status(Str serviceId, ServiceStatus status) {
		serviceIdToServiceStatus[serviceId].status = status
	}
}


class MutableServiceActivity : ServiceActivity {
	override Str 			serviceId
	override Type 			serviceType
	override ServiceStatus	status
	
	new make(|This|? f := null) {
		f?.call(this)
	}
}