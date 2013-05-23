
** Returns a map of all services defined by this IoC.
** 
** @since 1.2.0
const mixin ServiceStats {

	** Returns service stats, keyed by service id
	abstract Str:ServiceStat stats()
	
}

** Defines some statistics for a service
** 
** @since 1.2.0
const class ServiceStat {
	const Str 				serviceId
	const Type				type
	const ServiceScope 		scope
	const Bool				proxyDisabled
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
			it.proxyDisabled= this.proxyDisabled
			it.lifecycle	= newLifecycle
			it.noOfImpls	= this.noOfImpls
		}
	}

	internal This withNoOfImpls(Int newNoOfImpls) {
		ServiceStat {
			it.serviceId	= this.serviceId
			it.type			= this.type
			it.scope		= this.scope
			it.proxyDisabled= this.proxyDisabled
			it.lifecycle	= this.lifecycle
			it.noOfImpls	= newNoOfImpls
		}
	}
}

** Defines the lifecycle state of a service
** 
** @since 1.2.0
enum class ServiceLifecycle {

	** The service is defined in a module, but has not yet been referenced.
	DEFINED,

	** A proxy has been created for the service, but the implementation itself no methods of the proxy have been invoked.
	VIRTUAL,

	** A service implementation for the service has been created. It is real!
	CREATED,

	// leave this last for compare
	** Builtin services exist before the `Registry` is constructed.
	BUILTIN;
}
