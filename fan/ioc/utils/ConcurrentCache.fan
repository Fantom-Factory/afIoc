using concurrent::AtomicRef

** A helper class that wraps a 'Map' providing fast reads and synchronised writes between threads.
** 'ConcurrentCache' works in a similar vein to Java's [CopyOnWriteArrayList]`http://docs.oracle.com/javase/7/docs/api/java/util/concurrent/CopyOnWriteArrayList.html`
** and is useful for when *reads* far out number the *writes*.
** 
** 'ConcurrentCache' wraps a map stored in an [AtomicRef]`concurrent::AtomicRef` through which all 
** reads are made. All writes are made on a 'rw' copy of the map, of which an immutable version is 
** re-set back in in the 'AtomicRef'. Thus writes are a more expensive operation.
** 
** Note that all objects held in the map have to be immutable.
** 
** See [The Good, The Bad and The Ugly of Const Services]`http://www.fantomfactory.org/articles/good-bad-and-ugly-of-const-services#theBad` for more details.
** 
** @since 1.4.2
const class ConcurrentCache {
	private const AtomicRef atomicMap := AtomicRef()
	
	new make(|This|? f := null) {
		f?.call(this)
		this.map = [:]
	}

	** Make a 'ConcurrentCache' using the given immutable map. 
	** Use when you need a case insensitive map.
	** 
	** @since 1.4.6
	new makeWithMap([Obj:Obj?] map) {
		this.map = map 
	}
	
	** Returns and sets an immutable / read-only map. This *is* the cache.
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
	Obj? getOrAdd(Obj key, |Obj key->Obj?| valFunc) {
		if (!containsKey(key)) {
			val := valFunc.call(key)
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
		iKey  := key.toImmutable
		iVal  := val.toImmutable
		rwMap := map.rw
		rwMap[iKey] = iVal
		map = rwMap
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
		map = map.rw.clear
		return this
	}

	** Remove the key/value pair identified by the specified key
	** from the map and return the value. 
	** If the key was not mapped then return 'null'.
	Obj? remove(Obj key) {
		rwMap := map.rw
		oVal  := rwMap.remove(key)
		map = rwMap
		return oVal 
	}

	@NoDoc @Deprecated { msg="Use 'map' field instead" }
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
