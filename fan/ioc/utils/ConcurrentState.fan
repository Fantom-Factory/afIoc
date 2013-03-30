using concurrent

const class ConcurrentState {
	private static const Log 		log 		:= Utils.getLog(ConcurrentState#)
	private static const ActorPool	actorPool	:= ActorPool()
	private const Actor 			state		:= Actor(actorPool, |Obj? obj -> Obj?|  { receive(obj) })
	private const Type				stateType
	
	new make(Type stateType) {
		this.stateType = stateType
	}
	
	virtual protected Void withState(|Obj| f) {
		// use 'get' to so any Errs are re-thrown. As we're just setting / getting state the 
		// messages should be fast anyway (and we don't want a 'get' to happen before a 'set')
		state.send(f.toImmutable).get
	}
	
	virtual protected Obj? getState(|Obj->Obj?| f) {
		return state.send(f.toImmutable).get
	}	
	
	private Obj? receive(Obj? msg) {
		func := (msg as |Obj?->Obj?|)

		try {
			state := Actor.locals[stateType.qname]
			
			// lazily create out state
			if (state == null) {
				state = stateType.make
				Actor.locals[stateType.qname] = state
			}
			
			return func.call(state)
			
		} catch (Err e) {
			// if the func has a return type, then an the Err is rethrown on assignment
			// else we log the Err so the Thread doesn't fail silently
			if (func.returns == Void#)
				log.err("receive()", e)
			throw e
		}
	}	
}
