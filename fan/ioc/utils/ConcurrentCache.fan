using concurrent::AtomicRef
using concurrent::Future
using afIoc::ConcurrentState

** An application of `ConcurrentState` designed for fast reads where reads out number the writes.
** 
** The cache wraps a map stored in an [AtomicRef]`concurrent::AtomicRef` through which all reads 
** are made. All writes are made via [ConcurrentState]`afIoc::ConcurrentState` ensuring 
** synchronised access. Writing makes a rw copy of the map and is thus an expensive operation.
** 
** @since 1.4.2
const class ConcurrentCache {
	private const ConcurrentState 	conState	:= ConcurrentState(|->Obj?| { atomicMap })
	private const AtomicRef 		atomicMap	:= AtomicRef([:].toImmutable)
	
	private [Obj:Obj?] map {
		get { atomicMap.val }
		set { }
	}
	
	** Returns the value associated with the given key.
	@Operator
	Obj? get(Obj key) {
		map.get(key)
	}

	** Sets the key / value pair, ensuring no data is lost during multi-threaded race conditions.
	** Though the same key may be overridden. Both the 'key' and 'val' must be immutable. 
	@Operator
	Void set(Obj key, Obj val) {
		iKey := key.toImmutable
		iVal := val.toImmutable
		withState {
			myMap := map.rw
			myMap.set(iKey, iVal)
			atomicMap.val = myMap.toImmutable
		}.get
	}

	** Returns 'true' if the cache contains the given key
	Bool containsKey(Obj key) {
		map.containsKey(key)
	}

	private Future withState(|Obj?| state) {
		conState.withState(state)
	}
}
