using concurrent::ActorPool
using concurrent::AtomicRef
using concurrent::Future

** A helper class that wraps a 'Map' providing fast reads and synchronised writes betweeen threads.
** It's an application of `ConcurrentState` for use when *reads* far out number the *writes*.
** 
** The cache wraps a map stored in an [AtomicRef]`concurrent::AtomicRef` through which all reads 
** are made. All writes are made via [ConcurrentState]`afIoc::ConcurrentState` ensuring 
** synchronised access. Writing makes a 'rw' copy of the map and is thus a more expensive operation.
** 
** Note that all objects held in the map have to be immutable.
** 
** See [The Good, The Bad and The Ugly of Const Services]`http://www.fantomfactory.org/articles/good-bad-and-ugly-of-const-services#theUgly` for more details.
** 
** @since 1.4.2
const class ConcurrentCache : Synchronized {
	private const AtomicRef atomicMap := AtomicRef()
	
	** @since 1.5.6
	new make(ActorPool actorPool) : super(actorPool) {
		this.map = [:]
	}

	** Make a 'ConcurrentCache' using the given immutable map. 
	** Use when you need a case insensitive map.
	** 
	** @since 1.5.6
	new makeWithMap(ActorPool actorPool, [Obj:Obj?] map) : super.make(actorPool) {
		this.map = [:]
	}

	@NoDoc @Deprecated
	new makeOldSkool() : super.make() {
		this.map = [:]
	}

	** @since 1.4.6
	@NoDoc @Deprecated
	new makeOldSkoolWithMap([Obj:Obj?] map) : super.make() {
		this.map = map 
	}
	
	** A read-only copy of the cache map.
	[Obj:Obj?] map {
		get { atomicMap.val }
		set { atomicMap.val = it.toImmutable }
	}
	
	** Returns the value associated with the given key. If it doesn't exist then it is added from 
	** the value function. 
	** 
	** This method is **NOT** thread safe. If two actors call this method at the same time, the 
	** value function could be called twice for the same key.
	**  
	** @since 1.4.6
	Obj? getOrAdd(Obj key, |->Obj?| valFunc) {
		if (!containsKey(key)) {
			val := valFunc.call()
			set(key, val)
		}
		return get(key)
	}
	
	** Returns the value associated with the given key. 
	** If key is not mapped, then return the value of the 'def' parameter.  
	** If 'def' is omitted it defaults to 'null'.
	@Operator
	Obj? get(Obj key, Obj? def := null) {
		map.get(key, def)
	}

	** Sets the key / value pair, ensuring no data is lost during multi-threaded race conditions.
	** Though the same key may be overridden. Both the 'key' and 'val' must be immutable. 
	@Operator
	Void set(Obj key, Obj? val) {
		iKey := key.toImmutable
		iVal := val.toImmutable
		synchronized |->| {
			newMap := map.rw
			newMap.set(iKey, iVal)
			map = newMap
		}
	}

	** Returns 'true' if the cache contains the given key
	Bool containsKey(Obj key) {
		map.containsKey(key)
	}
	
	** Returns a list of all the mapped keys.
	Obj[] keys() {
		map.keys
	}

	** Returns a list of all the mapped values.
	Obj[] vals() {
		map.vals
	}

	** Remove all key/value pairs from the map. Return this.
	This clear() {
		synchronized |->| {
			map = map.rw.clear
		}
		return this
	}

	** Remove the key/value pair identified by the specified key
	** from the map and return the value. 
	** If the key was not mapped then return 'null'.
	Obj? remove(Obj key) {
		iKey := key.toImmutable
		return synchronized |->Obj?| {
			newMap := map.rw
			val := newMap.remove(iKey)
			map = newMap
			return val 
		}
	}

	@NoDoc @Deprecated { msg="Use 'map' setter instead" }
	Obj:Obj? replace(Obj:Obj? newMap) {
		map = newMap
	}
	
	** Return 'true' if size() == 0
	Bool isEmpty() {
		map.isEmpty
	}

	** Get the number of key/value pairs in the map.
	Int size() {
		map.size
	}	
}
