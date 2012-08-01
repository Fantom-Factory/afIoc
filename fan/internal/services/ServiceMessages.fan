
internal class ServiceMessages {
	
	// shutdown-listener-error=Error notifying %s of registry shutdown: %s
	static Str shutdownListenerError(Obj listener, Err cause) {
		"Error notifying ${listener} of registry shutdown: ${cause}"
	}
	
}
