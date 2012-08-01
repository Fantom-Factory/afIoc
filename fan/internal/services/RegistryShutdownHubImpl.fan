
internal class RegistryShutdownHubImpl : RegistryShutdownHub {
	
	private OneShotLock lock 			:= OneShotLock()
	private |->|[] 		listeners 		:= [,]
	private |->|[] 		preListeners 	:= [,]
	private Log			logger
	
	new make(Log logger) {
		this.logger = logger
	}
	
	override Void addRegistryShutdownListener(|->| listener) {
		lock.check
		listeners.add(listener)
	}

	override Void addRegistryWillShutdownListener(|->| listener) {
		lock.check
		preListeners.add(listener)
	}

	** After the listeners have been invoked, they are discarded to free up any references they may hold.
	Void fireRegistryDidShutdown() {
		lock.lock

		preListeners.each |listener| {
			try {
				listener()
			} catch (Err e) {
				logger.err(ServiceMessages.shutdownListenerError(listener, e))
			}
		}
		preListeners.clear

		listeners.each |listener| {
			try {
				listener()
			} catch (Err e) {
				logger.err(ServiceMessages.shutdownListenerError(listener, e))
			}
		}		
		listeners.clear
	}
}
