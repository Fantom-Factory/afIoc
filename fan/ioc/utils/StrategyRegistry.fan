
const class StrategyRegistry {	
	private const ConcurrentState 	conState	:= ConcurrentState(StrategyRegistryBestFitCache#)
	private const Type:Obj? 		values
	
	** Creates an AdapterPattern with the given list. All types are coerced to non-nullable types.
	** An 'Err' is thrown if a duplicate is found in the process. 
	new make(Type:Obj? values) {
		nonDups := Utils.makeMap(Type#, Obj?#)
		values.each |val, type| {
			nonNullable := type.toNonNullable
			if (nonDups.containsKey(nonNullable)) 
				throw Err("Type $nonNullable is already mapped to value ${nonDups[nonNullable]}")
			nonDups[nonNullable] = val
		}
		this.values = nonDups.toImmutable
	}

	Obj? findExactMatch(Type exact, Bool checked := true) {
		nonNullable := exact.toNonNullable
		return values.get(nonNullable)
			?: check(nonNullable, checked)
	}

	Obj? findBestFit(Type exact, Bool checked := true) {		
		nonNullable := exact.toNonNullable
		return getState |state->Obj?| {
			return state.cache.getOrAdd(nonNullable) |->Obj?| {
				deltas := values
					.findAll |val, type| { nonNullable.fits(type) }
					.map |val, type->Int| {
						inher 	:= nonNullable.inheritance
						min 	:= inher.index(nonNullable)	// should always be zero
						max 	:= inher.index(type)
						delta	:= max - min
						return delta
					}
				
				if (deltas.isEmpty)
					return null
				
				minDelta := deltas.vals.min
				match 	 := deltas.eachWhile |delta, type| { (delta == minDelta) ? type : null }
				return values[match]
			}
		} ?: check(nonNullable, checked)
	}

	private Obj? check(Type nonNullable, Bool checked) {
		checked ? throw NotFoundErr("Could not find match for Type ${nonNullable}.", values.keys) : null
	}
	
	private Obj? getState(|StrategyRegistryBestFitCache -> Obj| state) {
		conState.getState(state)
	}
}

internal class StrategyRegistryBestFitCache {
	Type:Obj? cache	:= [:]
}