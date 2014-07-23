using concurrent
using afConcurrent

internal class TestLocalRefDependencyProvider : IocTest {

	Void testInjection() {
		reg := RegistryBuilder().build.startup
		s96 := (T_MyService96) reg.autobuild(T_MyService96#)
		
		
		s96.localRef.val = 6
		s96.localList.add(6)
		s96.localMap[6] = 9
		
		verifyEq(s96.localRef.val, 6)
		verifyEq(s96.localList[0], 6)
		verifyEq(s96.localMap [6], 9)
		
		verify(s96          .localRef.qname.endsWith(".afIoc.T_MyService96.localRef" ))
		verify(s96.localList.localRef.qname.endsWith(".afIoc.T_MyService96.localList"))
		verify(s96.localMap .localRef.qname.endsWith(".afIoc.T_MyService96.localMap" ))

		verify(Actor.locals.containsKey(s96			 .localRef.qname))
		verify(Actor.locals.containsKey(s96.localList.localRef.qname))
		verify(Actor.locals.containsKey(s96.localMap .localRef.qname))

		// ensure the stash was created by the manager so it gets cleaned up
		(reg.dependencyByType(ThreadLocalManager#) as ThreadLocalManager).cleanUpThread
		verifyFalse(Actor.locals.containsKey(s96		  .localRef.qname))
		verifyFalse(Actor.locals.containsKey(s96.localList.localRef.qname))
		verifyFalse(Actor.locals.containsKey(s96.localMap .localRef.qname))
	}
	
}

internal class T_MyService96 {
	@Inject LocalRef? 	localRef
	@Inject LocalList?	localList
	@Inject LocalMap? 	localMap
}