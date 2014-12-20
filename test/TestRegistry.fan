
internal class TestRegistry : IocTest {
	
	Void testRegistryStartupIsDisabledOnceStarted() {
		reg := RegistryBuilder().addModule(T_MyModule01#).build
		
		// assert methods are okay before shutdown
		reg.startup
		
		verifyErr(IocErr#) { reg.startup }
	}

	Void testRegistryIsDisabledOnceShutdown() {
		reg := RegistryBuilder().addModule(T_MyModule01#).build.startup
		
		// assert methods are okay before shutdown
		reg.serviceById("t_myservice01")
		reg.dependencyByType(T_MyService01#)
		reg.autobuild(T_MyService01#)
		reg.injectIntoFields(T_MyService01())

		reg.shutdown

		verifyErr(IocShutdownErr#) { reg.startup }
		verifyErr(IocShutdownErr#) { reg.shutdown }
		verifyErr(IocShutdownErr#) { reg.serviceById("t_myservice01") }
		verifyErr(IocShutdownErr#) { reg.dependencyByType(T_MyService01#) }
		verifyErr(IocShutdownErr#) { reg.autobuild(T_MyService01#) }
		verifyErr(IocShutdownErr#) { reg.injectIntoFields(T_MyService01()) }
	}
	
	Void testServiceIdConflict() {
		verifyErr(IocErr#) { 
			RegistryBuilder().addModules([T_MyModule13#, T_MyModule14#]).build
		}
	}
}
