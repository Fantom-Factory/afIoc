using concurrent::Actor
using concurrent::ActorPool
using concurrent::AtomicInt
using concurrent::Future

** A helper class to store and retrieve state between threads; use in 'const' classes.
** For IoC this means your services can be declared as 'perApplication' or singleton scope and 
** still hold useful data.
** 
** In Java terms, the 'getState() { ... }' method behaves in a similar fashion to the 
** 'synchronized' keyword, only allowing one thread through at a time.
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
** A fully usable example of a mutable const map class is as follows:
** 
** pre>
** const class ConstMap {
**   const ConcurrentState  conState  := ConcurrentState(ConstMapState#)
**   
**   ** Note that both 'key' and 'value' need to be immutable
**   @Operator
**   Obj get(Obj key) {
**     getState |ConstMapState state -> Obj?| {
**       return state.map[key]
**     }
**   }
** 
**   ** Note that both 'key' and 'value' need to be immutable
**   @Operator
**   Void set(Obj key, Obj value) {
**     withState |ConstMapState state| {
**       state.map[key] = value
**     }
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
@NoDoc @Deprecated { msg="Use 'afConcurrent::SynchronizedState' instead" }
const class ConcurrentState {
	private static const Log 	log 		:= Utils.getLog(ConcurrentState#)
	
	** The 'ActorPool' used to store this object's 'Actor'. Set via a ctor it-block.
			const ActorPool		actorPool
	private const Actor 		stateActor
	private const |->Obj?| 		stateFactory
	private const ThreadStash 	stash
	
	** Keeps count of the number of 'ConcurrentState' instances that have been created.
	** For debug purposes.
	@NoDoc
	static const AtomicInt			instanceCount	:= AtomicInt() 
	
	private Obj? state {
		get { stash["state"] }
		set { stash["state"] = it }
	}

	** The given state type must have a public no-args ctor as per `sys::Type.make`
	new makeWithStateType(Type stateType, |This|? f := null) {
		f?.call(this)
		if (actorPool == null)
			actorPool = ActorPool()
		this.stateFactory	= |->Obj?| { stateType.make }
		this.stash			= ThreadStash(ConcurrentState#.name + "." + stateType.name)
		this.stateActor		= Actor(actorPool, |Obj? obj -> Obj?| { receive(obj) })
		instanceCount.incrementAndGet
//		Env.cur.err.printLine(Err().traceToStr.splitLines[4])
	}

	new makeWithStateFactory(|->Obj?| stateFactory, |This|? f := null) {
		f?.call(this)
		if (actorPool == null)
			actorPool = ActorPool()
		this.stateFactory	= stateFactory
		this.stash			= ThreadStash(ConcurrentState#.name + ".defaultName")
		this.stateActor		= Actor(actorPool, |Obj? obj -> Obj?| { receive(obj) })
		instanceCount.incrementAndGet
//		Env.cur.err.printLine(Err().traceToStr.splitLines[4])
	}

	** Use to access state, effectively wrapping the given func in a Java 'synchronized { ... }' 
	** block. Call 'get()' on the returned 'Future' to ensure any Errs are rethrown. 
	virtual Future withState(|Obj?->Obj?| f) {
		// explicit call to .toImmutable() - see http://fantom.org/sidewalk/topic/1798#c12190
		func	:= f.toImmutable
		future 	:= stateActor.send([true, func].toImmutable)
		return future
	}

	** Use to return state, effectively wrapping the given func in a Java 'synchronized { ... }' 
	** block. 
	virtual Obj? getState(|Obj?->Obj?| f) {
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
		logErr	:= msg[0] as Bool
		func 	:= msg[1] as |Obj->Obj?|

		try {
			// lazily create our state
			if (state == null) 
				state = stateFactory.call()

			return func.call(state)

		} catch (Err e) {
			// if the func has a return type, then an the Err is rethrown on assignment
			// else we log the Err so the Thread doesn't fail silently
			if (logErr || func.returns == Void#)
				log.err("receive()", e)
			throw e
		}
	}	
}

