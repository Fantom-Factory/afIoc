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
** A full example of a mutable const map class is as follows:
** 
** pre>
** const class ConstMap {
**   const ConcurrentState  conState  := ConcurrentState(ConstMapState#)
**   
**   Str get(Str key) {
**     getState {
**       it.map[key]
**     }
**   }
** 
**   Void put(Str key, Str value) {
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
**   Str:Str  map := [:]
** }
** <pre
** 
const class ConcurrentState {
	private static const Log 		log 		:= Utils.getLog(ConcurrentState#)
	private static const ActorPool	actorPool	:= ActorPool()
	private const Actor 			stateActor	:= Actor(actorPool, |Obj? obj -> Obj?|  { receive(obj) })
	private const Type				stateType
	private const LocalStash 		stash

	private Obj? state {
		get { stash["state"] }
		set { stash["state"] = it }
	}
	
	** The given state type must have a public no-args ctor as per `sys::Type.make`
	new make(Type stateType) {
		this.stateType	= stateType
		this.stash		= LocalStash(stateType)
	}
	
	** Use to access state
	virtual Void withState(|Obj| f) {
		// use 'get' to so any Errs are re-thrown. As we're just setting / getting state the 
		// messages should be fast anyway (and we don't want a 'get' to happen before a 'set')
		stateActor.send(f.toImmutable).get
	}
	
	** Use to return state
	virtual Obj? getState(|Obj->Obj?| f) {
		return stateActor.send(f.toImmutable).get
	}	
	
	protected Obj? receive(Obj? msg) {
		func := (msg as |Obj?->Obj?|)

		try {
			// lazily create our state
			if (state == null) 
				state = stateType.make
			
			return func.call(state)
			
		} catch (Err e) {
			// if the func has a return type, then an the Err is rethrown on assignment
			// else we log the Err so the Thread doesn't fail silently

			// commented out because 'withState' now calls 'get'
//			if (func.returns == Void#)
//				log.err("receive()", e)
			throw e
		}
	}	
}

