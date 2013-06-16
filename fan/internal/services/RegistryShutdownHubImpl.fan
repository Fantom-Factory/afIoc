
internal const class RegistryShutdownHubImpl : RegistryShutdownHub {
	private const static Log 		log 		:= Utils.getLog(RegistryShutdownHub#)
	private const ConcurrentState 	conState	:= ConcurrentState(RegistryShutdownHubState#)
 
	override Void addRegistryShutdownListener(Str id, Str[] constraints, |->| listener) {
		withState |state| {
			state.lock.check
			state.listeners.addOrdered(id, listener, constraints)
		}
	}

	override Void addRegistryWillShutdownListener(Str id, Str[] constraints, |->| listener) {
		withState |state| {
			state.lock.check
			state.preListeners.addOrdered(id, listener, constraints)
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

		withState |state| {
			state.preListeners.clear
		}
	}

	** After the listeners have been invoked, they are discarded to free up any references they may hold.
	internal Void registryHasShutdown() {
		withState |state| {
			state.lock.lock
		}

		listeners.each |listener| {
			try {
				listener()
			} catch (Err e) {
				log.err(IocMessages.shutdownListenerError(listener, e))
			}
		}
		
		withState |state| {
			state.listeners.clear
		}
	}
	
	private |->|[] preListeners() {
		getState |state| { state.preListeners.toOrderedList.toImmutable }
	}

	private |->|[] listeners() {
		getState |state| { state.listeners.toOrderedList.toImmutable }
	}

	private Void withState(|RegistryShutdownHubState| state) {
		conState.withState(state)
	}

	private Obj? getState(|RegistryShutdownHubState -> Obj| state) {
		conState.getState(state)
	}
}

internal class RegistryShutdownHubState {
	OneShotLock lock		:= OneShotLock(IocMessages.registryShutdown)
	Orderer preListeners	:= Orderer()
	Orderer listeners		:= Orderer()
}
