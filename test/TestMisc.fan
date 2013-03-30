
class TestMisc : Test {

	// see `RegistryImpl.trackDependencyByType`
	Void testFlatten() {
		verifyEq([4, [,], [[4]], 5].flatten, [,].addAll([4, 4, 5]))
	}
	
	
}
