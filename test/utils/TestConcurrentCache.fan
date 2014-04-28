using concurrent

internal class TestConcurrentCache : Test {
	
	Void testRemove() {
		cache := ConcurrentCache(ActorPool())
		cache["wot"] = 1
		cache["ever"] = 2
		verifyEq(cache.size, 2)

		cache.remove("wot")
		verifyNull(cache["wot"])
		verifyEq(cache["ever"], 2)
		verifyEq(cache.size, 1)
	}

	Void testClear() {
		cache := ConcurrentCache(ActorPool())
		cache["wot"] = "ever"
		verifyEq(cache.size, 1)
		cache.clear
		verify(cache.isEmpty)
	}

	Void testReplace() {
		cache := ConcurrentCache(ActorPool())
		cache["wot"] = 1
		verifyEq(cache.size, 1)
		
		cache.map = ["ever":2]
		verifyEq(cache["ever"], 2)
		verifyEq(cache.size, 1)
	}

	Void testGetOrAdd() {
		cache := ConcurrentCache(ActorPool())
		cache.getOrAdd("wot") { "ever" }
		verifyEq(cache.size, 1)
		verifyEq(cache["wot"], "ever")
		
		cache.getOrAdd("wot") { "ever" }
		verifyEq(cache.size, 1)
		verifyEq(cache["wot"], "ever")
	}
}
