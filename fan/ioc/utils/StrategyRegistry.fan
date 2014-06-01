using afConcurrent

@NoDoc @Deprecated { msg="Use afBeanUtils::TypeLookup instead" }
const class StrategyRegistry {
	private const CachingTypeLookup typeLookup

	new make(Type:Obj? values) {
		typeLookup = CachingTypeLookup(values)
	}

	Obj? findExactMatch(Type exact, Bool checked := true) {
		typeLookup.findExact(exact, checked)
	}

	Obj? findClosestParent(Type type, Bool checked := true) {
		typeLookup.findParent(type, checked)
	}
	
	Obj?[] findAllChildren(Type type) {
		typeLookup.findChildren(type, false)
	}
	
	** Clears the lookup caches
	Void clearCache() {
		typeLookup.clear
	}
	
	@NoDoc
	override Str toStr() {
		typeLookup.toStr
	}
}
