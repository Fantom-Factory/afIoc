
** As used by services which crate / compile new types and pods
internal const class TypeCache {

	private const ConcurrentState 	conState	:= ConcurrentState(TypeCacheState#)

	Bool containsKey(Str key) {
		getState { it.typeCache.containsKey(key) }
	}

	@Operator
	Type get(Str key) {
		getState { it.typeCache[key] }
	}
	
	@Operator
	Void set(Str key, Type val) {
		withState { it.typeCache[key] = val }
	}
	
	private Obj? getState(|TypeCacheState -> Obj| state) {
		conState.getState(state)
	}

	private Void withState(|TypeCacheState -> Obj| state) {
		conState.withState(state)
	}
}

internal class TypeCacheState {
	Str:Type	typeCache	:= [:]
}
