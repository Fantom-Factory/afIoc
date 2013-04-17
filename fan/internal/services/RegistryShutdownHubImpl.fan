
internal const class RegistryShutdownHubImpl : RegistryShutdownHub {
	private const static Log 		log 		:= Log.get(RegistryShutdownHubImpl#.name)
	private const ConcurrentState 	conState	:= ConcurrentState(RegistryShutdownHubState#)
 
	override Void addRegistryShutdownListener(|->| listener) {
		withMyState |state| {
			state.lock.check
			state.listeners.add(listener)
		}
	}

	override Void addRegistryWillShutdownListener(|->| listener) {
		withMyState |state| {
			state.lock.check
			state.preListeners.add(listener)
		}
	}

	** After the listeners have been invoked, they are discarded to free up any references they may hold.
	internal Void registryWillShutdown() {
		preListeners.each | |->| listener| {
			try {
				listener()
			} catch (Err e) {
				log.err(IocMessages.shutdownListenerError(listener, e))
			}
		}

		withMyState |state| {
			state.preListeners.clear
		}
	}

	** After the listeners have been invoked, they are discarded to free up any references they may hold.
	internal Void registryHasShutdown() {
		withMyState |state| {
			state.lock.lock
		}

		listeners.each |listener| {
			try {
				listener()
			} catch (Err e) {
				log.err(IocMessages.shutdownListenerError(listener, e))
			}
		}
		
		withMyState |state| {
			state.listeners.clear
		}
	}
	
	private |->|[] preListeners() {
		getMyState |state| { state.preListeners.toImmutable }
	}

	private |->|[] listeners() {
		getMyState |state| { state.listeners.toImmutable }
	}

	private Void withMyState(|RegistryShutdownHubState| state) {
		conState.withState(state)
	}

	private Obj? getMyState(|RegistryShutdownHubState -> Obj| state) {
		conState.getState(state)
	}
}

internal class RegistryShutdownHubState {
	OneShotLock lock	:= OneShotLock(IocMessages.registryShutdown)
	|->|[] preListeners	:= [,]
	|->|[] listeners	:= [,]
}
