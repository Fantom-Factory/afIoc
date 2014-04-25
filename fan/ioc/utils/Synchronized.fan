using concurrent::Actor
using concurrent::ActorPool
using concurrent::Future

const class Synchronized {
	private static const Log 	log 		:= Utils.getLog(ConcurrentState#)
	
	private const Actor actor

	new make(ActorPool? actorPool := null) {
		this.actor	= Actor(actorPool ?: ActorPool(), |Obj? obj -> Obj?| { receive(obj) })
	}

	** This effectively wraps the given func in a Java 'synchronized { ... }' block.
	** Err's that occur within the block are logged but not rethrown unless you call 'get()' on 
	** the returned 'Future'. 
	virtual Future synchronized(|Obj?->Obj?| f) {
		// explicit call to .toImmutable() - see http://fantom.org/sidewalk/topic/1798#c12190
		func	:= f.toImmutable
		future 	:= actor.send([true, func].toImmutable)
		try {
			return future.get
		} catch (NotImmutableErr err) {
			throw NotImmutableErr("Return value not immutable", err)
		}
	}

	** This effectively wraps the given func in a Java 'synchronized { ... }' block and returns a
	** value. 
	virtual Obj? synchronizedGet(|Obj?->Obj?| f) {
		// explicit call to .toImmutable() - see http://fantom.org/sidewalk/topic/1798#c12190
		func	:= f.toImmutable
		future := actor.send([false, func].toImmutable)
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
			return func.call(69)

		} catch (Err e) {
			// if the func has a return type, then an the Err is rethrown on assignment
			// else we log the Err so the Thread doesn't fail silently
			if (logErr || func.returns == Void#)
				log.err("receive()", e)
			throw e
		}
	}	
}
