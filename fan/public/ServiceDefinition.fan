using concurrent::AtomicInt
using concurrent::AtomicRef

** Service information, as returned by [Registry.serviceDefinitions()]`Registry.serviceDefinitions`.  
** 
** Note the data held this class does not change. 
** To see updates to 'lifecycle' and 'noOfImpls' a new instance of this class would need to be re-acquired from [Registry.serviceDefinitions()]`Registry.serviceDefinitions`.  
** 
** @since 1.2.0
const class ServiceDefinition {
	** The unique id of the service.
	const Str 				serviceId
	
	** The type of the service.
	const Type				serviceType
	
	** The scope of the service. 
	const ServiceScope 		serviceScope
	
	** The proxy strategy of the service.
	const ServiceProxy		serviceProxy
	
	** The current lifecycle of the service.
	const ServiceLifecycle	lifecycle
	
	** The number of times this service has been created.
	const Int				noOfImpls		

	@NoDoc
	override const Str		toStr		

	internal new make(|This| f) { f(this) }	
}

