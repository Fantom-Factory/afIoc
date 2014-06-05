using concurrent::Future
using afConcurrent::SynchronizedState

** (Service) - Contribute functions to be executed on `Registry` shutdown. 
** All functions need to be immutable, which essentially means they can only reference 'const' classes.
** 
** Common usage is add listeners in your service ctor:
** 
** pre>
** const class MyService {
**  
**   new make(RegistryShutdownHub shutdownHub) {
**     shutdownHub.addRegistryShutdownListener("Stuff", [,]) |->| {
**       doStuff()
**     }
**   }
** }
** <pre
** 
** Note that Errs thrown by shutdown functions will be logged and ignored.
const mixin RegistryShutdownHub {

	** Adds a listener that will be notified when the registry shuts down. Note when shutdown 
	** listeners are called, the state of other dependent services is unassured. If your listener 
	** depends on other services use 'addRegistryWillShutdownListener()' 
	**  
	** Errs thrown by the listener will be logged and ignored.
	** 
	** Each listener has a unique id (case insensitive) that is used by the constraints for 
	** ordering. Each constraint must start with the prefix 'BEFORE:' or 'AFTER:'.
	** 
	** pre>
	**   config.addOrdered("Breakfast", eggs)
	**   config.addOrdered("Lunch", ["AFTER: breakfast", "BEFORE: dinner"], ham)
	**   config.addOrdered("Dinner", pie)
	** <pre
	abstract Void addRegistryShutdownListener(Str id, Str[] constraints, |->| listener)

	** Adds a listener that will be notified when the registry shuts down. RegistryWillShutdown 
	** listeners are notified before shutdown listeners.
	** 
	** Errs thrown by the listener will be logged and ignored.
	** 
	** Each listener has a unique id (case insensitive) that is used by the constraints for 
	** ordering. Each constraint must start with the prefix 'BEFORE:' or 'AFTER:'.
	** 
	** pre>
	**   config.addOrdered("Breakfast", eggs)
	**   config.addOrdered("Lunch", ["AFTER: breakfast", "BEFORE: dinner"], ham)
	**   config.addOrdered("Dinner", pie)
	** <pre
	abstract Void addRegistryWillShutdownListener(Str id, Str[] constraints, |->| listener)
}


internal const class RegistryShutdownHubImpl : RegistryShutdownHub {
	private const static Log 		log 		:= Utils.getLog(RegistryShutdownHub#)
	private const OneShotLock 		lock		:= OneShotLock(IocMessages.registryShutdown)
	private const SynchronizedState	conState
 
	new make(ActorPools actorPools) {
		conState = SynchronizedState(actorPools["afIoc.system"], RegistryShutdownHubState#)
	}
	
	override Void addRegistryShutdownListener(Str id, Str[] constraints, |->| listener) {
		lock.check
		iHandler := listener.toImmutable
		withState |state| {
			state.listeners.addOrdered(id, iHandler, constraints)
		}.get
	}

	override Void addRegistryWillShutdownListener(Str id, Str[] constraints, |->| listener) {
		lock.check
		iHandler := listener.toImmutable
		withState |state| {
			state.preListeners.addOrdered(id, iHandler, constraints)
		}.get
	}

	** After the listeners have been invoked, they are discarded to free up any references they may hold.
	internal Void registryWillShutdown() {
		preListeners.each | |->| listener| {
			try {
				listener.call
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
		lock.lock

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

	private Future withState(|RegistryShutdownHubState| state) {
		conState.withState(state)
	}

	private Obj? getState(|RegistryShutdownHubState -> Obj| state) {
		conState.getState(state)
	}
}

internal class RegistryShutdownHubState {
	Orderer preListeners	:= Orderer()
	Orderer listeners		:= Orderer()
}
