using concurrent::AtomicInt
using concurrent::AtomicRef

** (Service) - Holds a list of all the services defined by this IoC.
** 
** @since 1.2.0
const mixin ServiceStats {

	** Returns [service stats]`ServiceStat`, keyed by service id.
	abstract Str:ServiceDefinition stats()	
}

** @since 1.2.0
internal const class ServiceStatsImpl : ServiceStats {
	
	private const ObjLocator objLocator
	
	new make(Registry registry) {
		this.objLocator = (ObjLocator) registry
	}
	
	override Str:ServiceDefinition stats() {
		objLocator.stats
	}
}

** As returned by `ServiceStats`. Defines some basic statistics for a service.
** 
** @since 1.2.0
const class ServiceDefinition {
	private const AtomicRef		atomLifecycle	:= AtomicRef()
	private const AtomicInt		atomNoOfImpls	:= AtomicInt()

	const Str 			serviceId
	const Type			serviceType
	const ServiceScope 	serviceScope
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

