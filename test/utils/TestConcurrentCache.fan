using concurrent

internal class TestConcurrentCache : IocTest {
	
	Void testThreadedAccess() {
		cache := ConcurrentCache()

		cache[1] = 1
		cache[2] = 2

		pool := ActorPool()
		Actor(pool) |->| {
			cache[2] = 3
			cache[3] = 4
		}.send(null)

		Actor(pool) |->| {
			cache[3] = 5
			cache[4] = 6
		}.send(null)
		
		pool.stop.join
		
		verifyEq(cache[1], 1)
		verifyEq(cache[2], 3)
		verifyEq(cache[3], 5)
		verifyEq(cache[4], 6)
	}
}
