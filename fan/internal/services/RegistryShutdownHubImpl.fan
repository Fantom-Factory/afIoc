
internal class RegistryShutdownHubImpl : RegistryShutdownHub {
	private const static Log 	log 		:= Log.get(RegistryShutdownHubImpl#.name)
	
	private OneShotLock lock 			:= OneShotLock()
	private |->|[] 		preListeners 	:= [,]
	private |->|[] 		listeners 		:= [,]

	
	
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
				log.err(ServiceMessages.shutdownListenerError(listener, e))
			}
		}
		preListeners.clear

		listeners.each |listener| {
			try {
				listener()
			} catch (Err e) {
				log.err(ServiceMessages.shutdownListenerError(listener, e))
			}
		}		
		listeners.clear
	}
}
