
@Js
internal class TestRegistryShutdown : IocTest {

	Void testRegistryIsDisabledOnceShutdown() {
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

		reg.shutdown
		reg.shutdown

		verifyErr(RegistryShutdownErr#) { reg.rootScope }
	}
	
	Void testServiceIdConflict() {
		verifyErr(IocErr#) { 
			RegistryBuilder().addModule(T_MyModule13#).addModule(T_MyModule14#).build
		}
	}
}
