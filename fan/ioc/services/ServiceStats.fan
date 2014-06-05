using concurrent::AtomicInt
using concurrent::AtomicRef

** (Service) - Holds a list of all the services defined by this IoC.
** 
** @since 1.2.0
const mixin ServiceStats {

	** Returns [service stats]`ServiceStat`, keyed by service id.
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
@NoDoc	// This is a boring class - and just adds clutter!
const class ServiceStat {
	private const AtomicRef		atomLifecycle	:= AtomicRef()
	private const AtomicInt		atomNoOfImpls	:= AtomicInt()

	const Str 			serviceId
	const Type			serviceType
	const ServiceScope 	scope
	const Bool			proxyDisabled
	ServiceLifecycle	lifecycle {
				 get {	atomLifecycle.val }
		internal set {	atomLifecycle.val = it}
	}
	Int					noOfImpls {
				 get {	atomNoOfImpls.val }
		internal set {	atomNoOfImpls.val = it}		
	}

	internal new make(|This| f) { f(this) }
	
	internal Void incImpls() {
		atomNoOfImpls.incrementAndGet
	}
	
	internal Void updateLifecycle(ServiceLifecycle newLifecycle) {
		if (newLifecycle > lifecycle)
			lifecycle = newLifecycle
	}
}

** Used by `ServiceStat` to define the lifecycle state of a service. 
** A service lifecycle looks like:
** 
** pre>
** DEFINED - the service is defined in a module
**   ||
**   \/
** VIRTUAL - a proxy has been created and the service may be injected
**   ||
**   \/
** CREATED - the implementation has been created and the service is live
** <pre
** 
** The service implementation is created on demand when methods on the proxy are called.
** 
** Note that if a service does not have a proxy, the 'VIRTUAL' stage is skipped.
** 
** @since 1.2.0
enum class ServiceLifecycle {

	** The service is defined in a module, but has not yet been referenced.
	DEFINED,

	** A proxy has been created for the service and may be injected into other services. 
	** No methods of the proxy have been invoked and the implementation does yet not exist.
	VIRTUAL,

	** The service implementation has been created. It lives!
	CREATED,

	// leave this last for compare
	** Builtin services are internal IoC services. They exist before the `Registry` is constructed.
	BUILTIN;
}
