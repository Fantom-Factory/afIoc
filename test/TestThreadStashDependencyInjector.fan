
internal class TestThreadStashDependencyInjector : IocTest {

	Void testInjection() {
		reg := RegistryBuilder().build.startup
		s96 := (T_MyService96) reg.autobuild(T_MyService96#)
		Env.cur.err.printLine(s96.stash.prefix)
		verify(s96.stash.prefix.contains(".T_MyService96."))
		
		s96.stash["wot"] = "ever"
		verify(s96.stash.contains("wot"))
		
		// ensure the stash was created by the manager so it gets cleaned up
		(reg.dependencyByType(ThreadStashManager#) as ThreadStashManager).cleanUpThread
		verifyFalse(s96.stash.contains("wot"))
	}
	
}

internal class T_MyService96 {
	@Inject ThreadStash stash
	new make(|This|in) { in(this) }
}