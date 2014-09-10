
** As returned by `ServiceDefinition` to define the lifecycle state of a service. 
** A service lifecycle looks like:
** 
** pre>
** Defined - the service is defined in a module
**   ||
**   \/
** Proxied - a proxy has been created and the service may be injected
**   ||
**   \/
** Created - the implementation has been created and the service is live
** <pre
** 
** The service implementation is created on demand when methods on the proxy are called.
** 
** Note that if a service does not have a proxy, the 'Proxied' stage is skipped.
** 
** @since 1.2.0
enum class ServiceLifecycle {

	** The service is defined in a module, but has not yet been referenced.
	defined,

	** A proxy has been created for the service and may be injected into other services. 
	** No methods of the proxy have been invoked and the implementation does yet not exist.
	proxied,

	** The service implementation has been created. It lives!
	created,

	// leave this last for compare
	** Builtin services are internal IoC services. They exist before the `Registry` is constructed.
	builtin;
}
