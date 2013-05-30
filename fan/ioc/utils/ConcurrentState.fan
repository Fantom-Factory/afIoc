using concurrent

**
** A helper class used to store, access and retrieve mutable state within a 'const' class. For IoC 
** this means your services can be declared as 'perApplication' or singleton scope.
** 
** 'ConcurrentState' wraps a state object in an Actor, and provides access to it via the 
** 'withState' and 'getState' methods. Note that by their nature, these methods are immutable 
** boundaries. Meaning that while all data in the State object can be mutable, but data passed in 
** and out of the methods can not be. 
** 
** 'ConcurrentState' has been designed to be *type safe*, that is you cannot accidently call 
** methods on your State object. The compiler forces all access to the state object to be made 
** through the 'withState' and 'getState' methods.
** 
** A full example of a mutable const map class is as follows:
** 
** pre>
** const class ConstMap {
**   const ConcurrentState  conState  := ConcurrentState(ConstMapState#)
**   
**   ** Note that both 'key' and 'value' need to be immutable
**   @Operator
**   Obj get(Obj key) {
**     getState {
**       it.map[key]
**     }
**   }
** 
**   ** Note that both 'key' and 'value' need to be immutable
**   @Operator
**   Void set(Obj key, Obj value) {
**     withState {
**       it.map[key] = value
**     }
**   }
**   
**   ** helper method used to narrow the state type
**   private Void withState(|ConstMapState| state) {
**     conState.withState(state)
**   }
** 
**   ** helper method used to narrow the state type
**   private Obj? getState(|ConstMapState -> Obj| state) {
**     conState.getState(state)
**   }
** }
** 
** class ConstMapState {
**   Obj:Obj  map := [:]
** }
** <pre
** 
** As alternatives to 'ConcurrentState' don't forget you also have 
** [AtomicBool]`concurrent::AtomicBool`, [AtomicInt]`concurrent::AtomicInt` and 
** [AtomicRef]`concurrent::AtomicRef`
** 
const class ConcurrentState {
	private static const Log 		log 		:= Utils.getLog(ConcurrentState#)
	private static const ActorPool	actorPool	:= ActorPool()
	private const Actor 			stateActor	:= Actor(actorPool, |Obj? obj -> Obj?|  { receive(obj) })
	private const |->Obj| 			stateFactory
	private const ThreadStash 		stash

	private Obj? state {
		get { stash["state"] }
		set { stash["state"] = it }
	}

	** The given state type must have a public no-args ctor as per `sys::Type.make`
	new makeWithStateType(Type stateType) {
		this.stateFactory	= |->Obj| { stateType.make }
		this.stash			= ThreadStash(ConcurrentState#.name + "." + stateType.name)
	}

	new makeWithStateFactory(|->Obj| stateFactory) {
		this.stateFactory	= stateFactory
		this.stash			= ThreadStash(ConcurrentState#.name + ".defaultName")
	}

	** Use to access state
	virtual Void withState(|Obj| f, Bool waitForErr := true) {
		// explicit call to .toImmutable() - see http://fantom.org/sidewalk/topic/1798#c12190
		func	:= f.toImmutable
		future 	:= stateActor.send([!waitForErr, func].toImmutable)

		// use 'get' to so any Errs are re-thrown. As we're just setting / getting state the 
		// messages should be fast anyway (and we don't want a 'get' to happen before a 'set')
		// Turn this off for event listeners when you really don't need it 
		if (waitForErr)
			get(future)
	}

	** Use to return state
	virtual Obj? getState(|Obj->Obj?| f) {
		// explicit call to .toImmutable() - see http://fantom.org/sidewalk/topic/1798#c12190
		func	:= f.toImmutable
		future := stateActor.send([false, func].toImmutable)
		return get(future)
	}

	private Obj? get(Future future) {
		try {
			return future.get
		} catch (NotImmutableErr err) {
			throw NotImmutableErr("Return value not immutable", err)
		}
	}

	private Obj? receive(Obj[] msg) {
		reportErr	:= msg[0] as Bool
		func 		:= msg[1] as |Obj?->Obj?|

		try {
			// lazily create our state
			if (state == null) 
				state = stateFactory()

			return func.call(state)

		} catch (Err e) {
			// if the func has a return type, then an the Err is rethrown on assignment
			// else we log the Err so the Thread doesn't fail silently
			if (reportErr || func.returns == Void#)
				log.err("receive()", e)
			throw e
		}
	}	
}

