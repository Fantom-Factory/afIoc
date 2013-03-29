
class TestRegistry : Test {
	
	Void testRegistryStartupIsDisabledOnceStarted() {
		reg := RegistryBuilder().addModule(T_MyModule1#).build
		
		// assert methods are okay before shutdown
		reg.startup
		
		verifyErr(IocErr#) { reg.startup }
	}

	Void testRegistryIsDisabledOnceShutdown() {
		reg := RegistryBuilder().addModule(T_MyModule1#).build.startup
		
		// assert methods are okay before shutdown
		reg.serviceById("t_myservice1")
		reg.dependencyByType(T_MyService1#)
		reg.autobuild(T_MyService1#)
		reg.injectIntoFields(T_MyService1())
		
		reg.shutdown
		
		verifyErr(IocErr#) { reg.startup }
		verifyErr(IocErr#) { reg.shutdown }
		verifyErr(IocErr#) { reg.serviceById("t_myservice1") }
		verifyErr(IocErr#) { reg.dependencyByType(T_MyService1#) }
		verifyErr(IocErr#) { reg.autobuild(T_MyService1#) }
		verifyErr(IocErr#) { reg.injectIntoFields(T_MyService1()) }
	}
	
	Void testServiceIdConflict() {
		verifyErr(IocErr#) { 
			RegistryBuilder().addModules([T_MyModule1#, T_MyModule1#]).build
		}
	}
	
}

internal class T_MyModule11 {
	static Void bind(ServiceBinder binder) {
		
	}
}
