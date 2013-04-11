
internal class ServiceMessages {
	
	static Str shutdownListenerError(Obj listener, Err cause) {
		"Error notifying ${listener} of registry shutdown: ${cause}"
	}
	
	static Str serviceIdDoesNotFit(Str serviceId, Type serviceType, Type fieldType) {
		"Service Id '${serviceId} of type ${serviceType.qname} does not fit type ${fieldType.qname}"
	}
	
	static Str dependencyDoesNotFit(Type dependencyType, Type fieldType) {
		"Dependency of type ${dependencyType.qname} does not fit type ${fieldType.qname}"
	}
	
	static Str onlyOneDependencyProviderAllowed(Type type, Type[] dps) {
		"Only one Dependency Provider is allowed, but type ${type.qname} matches ${dps.size} : " + dps.map { it.qname }.join(", ")
	}
}
