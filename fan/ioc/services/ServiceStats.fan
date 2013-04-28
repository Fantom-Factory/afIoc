
** Returns a map of all services defined by this IoC.
const mixin ServiceStats {

	** Returns service stats, keyed by service id
	abstract Str:ServiceStat stats()
	
}

internal const class ServiceStatsImpl : ServiceStats {
	
	private const RegistryImpl registry
	
	new make(RegistryImpl registry) {
		this.registry = registry
	}
	
	override Str:ServiceStat stats() {
		registry.stats
	}
}

** Defines some statistics for a service
const class ServiceStat {
	const Str 				serviceId
	const Type				type
	const ServiceScope 		scope
	const ServiceLifecycle	lifecycle
	const Int				noOfImpls

	internal new make(|This|? f) { f?.call(this) }

	internal This withLifecyle(ServiceLifecycle newLifecycle) {
		if (newLifecycle.ordinal <= lifecycle.ordinal) 
			return this
		
		return ServiceStat {
			it.serviceId	= this.serviceId
			it.type			= this.type
			it.scope		= this.scope
			it.lifecycle	= newLifecycle
			it.noOfImpls	= this.noOfImpls
		}
	}

	internal This withNoOfImpls(Int newNoOfImpls) {
		ServiceStat {
			it.serviceId	= this.serviceId
			it.type			= this.type
			it.scope		= this.scope
			it.lifecycle	= this.lifecycle
			it.noOfImpls	= newNoOfImpls
		}
	}
}

** Defines the lifecycle state of a service
enum class ServiceLifecycle {

	** The service is defined in a module, but has not yet been referenced.
	DEFINED,

	// Not yet!
//	** A proxy has been created for the service, but no methods of the proxy have been invoked.
//	VIRTUAL,

	** A service implementation for the service has been created.
	CREATED,

	** Builtin services exist before the `Registry` is constructed.
	BUILTIN;
}