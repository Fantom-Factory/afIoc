
@Js
internal class TestScopeDestroy : IocTest {
	
	Void testScopeIsDisabledOnceDestroyed() {
		reg := RegistryBuilder() { addScope("thread", true) }.addModule(T_MyModule01#).build
		thread := (Scope?) null
		reg.rootScope.createChildScope("thread") {
			thread = it.jailBreak
		}
		
		// assert methods are okay before shutdown
		thread.serviceById(T_MyService01#.qname)
		thread.serviceByType(T_MyService01#)
		thread.build(T_MyService01#)
		thread.inject(T_MyService01())

		thread.destroy

		verifyErr(ScopeDestroyedErr#) { thread.serviceById(T_MyService01#.qname) }
		verifyErr(ScopeDestroyedErr#) { thread.serviceByType(T_MyService01#) }
		verifyErr(ScopeDestroyedErr#) { thread.build(T_MyService01#) }
		verifyErr(ScopeDestroyedErr#) { thread.inject(T_MyService01()) }
	}
}
