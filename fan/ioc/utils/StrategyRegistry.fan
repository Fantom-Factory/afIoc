
** A helper class that looks up Objs via Type inheritance search.
const class StrategyRegistry {	
	private const DangerCache 	parentCache		:= DangerCache([Type:Obj?][:])
	private const DangerCache 	childrenCache	:= DangerCache([Type:Obj?[]][:])
	private const Type:Obj? 	values
	
	** Creates an StrategyRegistry with the given list. All types are coerced to non-nullable types.
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

	** Standard Map behaviour - looks up an Obj via the type. 
	Obj? findExactMatch(Type exact, Bool checked := true) {
		nonNullable := exact.toNonNullable
		return values.get(nonNullable)
			?: check(nonNullable, checked)
	}

	** Returns the value of the closest parent of the given type.
	** Example:
	** pre>
	**   strategy := StrategyRegistry( [Obj#:1, Num#:2, Int#:3] )
	**   strategy.findClosestParent(Obj#)   // --> 1
	**   strategy.findClosestParent(Num#)   // --> 2
	**   strategy.findClosestParent(Float#) // --> 2
	** <pre
	Obj? findClosestParent(Type type, Bool checked := true) {
		nonNullable := type.toNonNullable
		// chill, I got tests for all this!
		return parentCache.getOrAdd(nonNullable) |->Obj?| {
			deltas := values
				.findAll |val, t2| { nonNullable.fits(t2) }
				.map |val, t2->Int?| {
					nonNullable.inheritance.eachWhile |sup, i| {
						(sup == t2 || sup.mixins.contains(t2)) ? i : null
					}
				}
			
			if (deltas.isEmpty)
				return null
			
			minDelta := deltas.vals.min
			match 	 := deltas.eachWhile |delta, t2| { (delta == minDelta) ? t2 : null }
			return values[match]
		} ?: check(nonNullable, checked)
	}
	
	** Returns the values of the children of the given type.
	** Example:
	** pre>
	**   strategy := StrategyRegistry( [Obj#:1, Num#:2, Int#:3] )
	** 	 strategy.findChildrenOf(Obj#)   // --> [1, 2, 3]
	**   strategy.findChildrenOf(Num#)   // --> [2, 3]
	**   strategy.findChildrenOf(Float#) // --> [,]
	** <pre
	Obj?[] findChildren(Type type) {
		nonNullable := type.toNonNullable
		return childrenCache.getOrAdd(nonNullable) |->Obj?[]| {
			values.findAll |val, key| { key.fits(type) }.vals
		}
	}
	
	@NoDoc @Deprecated { msg="Use findClosestParent() instead" }  
	Obj? findBestFit(Type bestFit, Bool checked := true) {
		findClosestParent(bestFit, checked)
	}

	** Clears the lookup caches
	Void clearCache() {
		parentCache.clear
		parentCache.clear
	}
	
	private Obj? check(Type nonNullable, Bool checked) {
		checked ? throw NotFoundErr("Could not find match for Type ${nonNullable}.", values.keys) : null
	}
	
	@NoDoc
	override Str toStr() {
		values.keys.toStr
	}
}
