
internal class ServiceMessages {
	
	static Str shutdownListenerError(Obj listener, Err cause) {
		"Error notifying ${listener} of registry shutdown: ${cause}"
	}
	
	static Str serviceIdDoesNotFitField(Str serviceId, Type serviceType, Type fieldType) {
		"Service Id '${serviceId} of type ${serviceType.qname} does not fit field type ${fieldType.qname}"
	}
}
