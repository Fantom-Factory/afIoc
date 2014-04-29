using concurrent::ActorPool
using afConcurrent::SynchronizedMap

@NoDoc @Deprecated { msg="Use 'afConcurrent::SynchronizedMap' instead" }
const class ConcurrentCache {
	private const SynchronizedMap 	sMap
	
	new make(|This|? f := null) {
		f?.call(this)
		this.sMap = SynchronizedMap(ActorPool())
	}

	new makeWithMap([Obj:Obj?] map) {
		this.sMap = SynchronizedMap(ActorPool())
		this.sMap.map = map
	}
	
	[Obj:Obj?] map {
		get { sMap.map }
		private set { sMap.map = it }
	}
	
	Obj? getOrAdd(Obj key, |->Obj?| valFunc) {
		sMap.getOrAdd(key, valFunc)
	}
	
	@Operator
	Obj? get(Obj key, Obj? def := null) {
		sMap.get(key, def)
	}

	@Operator
	Void set(Obj key, Obj? val) {
		sMap.set(key, val)
	}

	Bool containsKey(Obj key) {
		sMap.containsKey(key)
	}
	
	Obj[] keys() {
		sMap.keys
	}

	Obj[] vals() {
		sMap.vals
	}

	This clear() {
		sMap.clear
		return this
	}

	Obj? remove(Obj key) {
		sMap.remove(key)
	}

	Obj:Obj? replace(Obj:Obj? newMap) {
		sMap.map = newMap
	}
	
	Bool isEmpty() {
		sMap.isEmpty
	}

	Int size() {
		sMap.size
	}
}
