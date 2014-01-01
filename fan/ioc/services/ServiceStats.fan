
** (Service) - Holds a list of all the services defined by this IoC.
** 
** @since 1.2.0
const mixin ServiceStats {

	** Returns service stats, keyed by service id.
	abstract Str:ServiceStat stats()	
}

** @since 1.2.0
internal const class ServiceStatsImpl : ServiceStats {
	
	private const ObjLocator objLocator
	
	new make(Registry registry) {
		this.objLocator = (ObjLocator) registry
	}
	
	override Str:ServiceStat stats() {
		objLocator.stats
	}
}

** As returned by `ServiceStats`. Defines some basic statistics for a service.
** 
** @since 1.2.0
const class ServiceStat {
	const Str 				serviceId
	const Type				serviceType
	const ServiceScope 		scope
	const Bool				proxyDisabled
	const ServiceLifecycle	lifecycle
	const Int				noOfImpls

	@NoDoc @Deprecated { msg="Use 'serviceType' instead." }
		  Type				type() { serviceType }

	internal new make(|This|? f) { f?.call(this) }

	internal This withLifecyle(ServiceLifecycle newLifecycle) {
		ServiceStat {
			it.serviceId	= this.serviceId
			it.serviceType	= this.serviceType
			it.scope		= this.scope
			it.proxyDisabled= this.proxyDisabled
			it.lifecycle	= newLifecycle
			it.noOfImpls	= this.noOfImpls
		}
	}

	internal This withIncImpls() {
		ServiceStat {
			it.serviceId	= this.serviceId
			it.serviceType	= this.serviceType
			it.scope		= this.scope
			it.proxyDisabled= this.proxyDisabled
			it.lifecycle	= this.lifecycle
			it.noOfImpls	= this.noOfImpls + 1
		}
	}
}

** Used by `ServiceStat` to define the lifecycle state of a service
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
