
class TestConcurrentCache : Test {
	
	Void testRemove() {
		cache := ConcurrentCache()
		cache["wot"] = 1
		cache["ever"] = 2
		verifyEq(cache.size, 2)

		cache.remove("wot")
		verifyNull(cache["wot"])
		verifyEq(cache["ever"], 2)
		verifyEq(cache.size, 1)
	}

	Void testClear() {
		cache := ConcurrentCache()
		cache["wot"] = "ever"
		verifyEq(cache.size, 1)
		cache.clear
		verify(cache.isEmpty)
	}

	Void testReplace() {
		cache := ConcurrentCache()
		cache["wot"] = 1
		verifyEq(cache.size, 1)
		
		cache.replace(["ever":2])
		verifyEq(cache["ever"], 2)
		verifyEq(cache.size, 1)
	}
}
