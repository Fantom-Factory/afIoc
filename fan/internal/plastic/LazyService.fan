
const class LazyService {
	private const Registry 	registry
	private const Str		serviceId
	
	new make(Registry registry, Str serviceId) {
		this.registry 	= registry
		this.serviceId 	= serviceId
	}

	Obj get() {
		// TODO: cache service and avoid the lookup
		registry.serviceById(serviceId)
	}
}
