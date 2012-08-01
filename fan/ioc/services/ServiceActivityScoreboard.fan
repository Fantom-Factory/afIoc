
**
** Provides access to the runtime details about services in the `Registry`.
** 
mixin ServiceActivityScoreboard {

	** Returns the status of all services, sorted alphabetically by service id.
	abstract ServiceActivity[] serviceActivity()
}



**
** Provided by the `ServiceActivityScoreboard` to track a single service's state and activity.
** 
mixin ServiceActivity {

	** The unique id for the service.
	abstract Str serviceId()

	** The type implemented by the service
	abstract Type serviceType()

	** Indicates the lifecycle status of the service.
	abstract ServiceStatus status()
}



**
** Identifies the state of the service in terms of its overall lifecycle.
** 
enum class ServiceStatus {

	** A builtin service that exists before the `Registry` is constructed.
	BUILTIN,

	** The service is defined in a module, but has not yet been referenced.
	DEFINED,

	// TODO:
//	** A proxy has been created for the service, but no methods of the proxy have been invoked.
//	VIRTUAL,

	** A service implementation for the service has been created.
	REAL
}