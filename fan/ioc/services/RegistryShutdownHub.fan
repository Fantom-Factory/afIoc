**
** Event hub for notifications when the IOC `Registry` shuts down.
** 
mixin RegistryShutdownHub {

	** Adds a listener for eventual notification when the registry shuts down. 
	** Runtime exceptions thrown by the listener will be logged and ignored.
	abstract Void addRegistryShutdownListener(|->| listener)

	** Adds a listener for eventual notification. RegistryWillShutdownListeners are notified before any standard listeners.
	** Runtime exceptions thrown by the listener will be logged and ignored.
	abstract Void addRegistryWillShutdownListener(|->| listener)
	
}
