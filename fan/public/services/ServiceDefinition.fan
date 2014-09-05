using concurrent::AtomicInt
using concurrent::AtomicRef

** Holds meta info about a service, as returned by `Registry.serviceDefinitions()`.  
** 
** @since 1.2.0
const class ServiceDefinition {
	const Str 				serviceId
	const Type				serviceType
	const ServiceScope 		serviceScope
	const ServiceProxy		serviceProxy
	const ServiceLifecycle	lifecycle
	const Int				noOfImpls		

	override const Str		toStr		

	internal new make(|This| f) { f(this) }	
}

