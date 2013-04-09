
**
** Event hub for notifications when the `Registry` shuts down. All listeners need to immutable 
** funcs, which essentially means only 'const' classes can contribute.
** 
** Common usage is add listeners in your service ctor:
** 
** pre>
**   new make(RegistryShutdownHub shutdownHub) {
**     shutdownHub.addRegistryShutdownListener |->| {
**       this.shutdown
**     }
**   }
** <pre
** 
// TODO: make listeners ordered
const mixin RegistryShutdownHub {

	** Adds a listener that will be notified when the registry shuts down. Note when shutdown 
	** listeners are called, the state of other dependent services is unassured. If your listener 
	** depends on other services use 'addRegistryWillShutdownListener()' 
	**  
	** Errs thrown by the listener will be logged and ignored.
	abstract Void addRegistryShutdownListener(|->| listener)

	** Adds a listener that will be notified when the registry shuts down. RegistryWillShutdown 
	** listeners are notified before shutdown listeners.
	** 
	** Errs thrown by the listener will be logged and ignored.
	abstract Void addRegistryWillShutdownListener(|->| listener)
	
}
