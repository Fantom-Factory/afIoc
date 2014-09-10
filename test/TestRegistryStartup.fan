
internal class TestRegistryStartup : IocTest {
	
	Void testRegistryStartup() {
		reg := RegistryBuilder().addModule(T_MyModule39#).build.startup
		T_MyService02 s2 := reg.serviceById("s2")
		verifyEq(s2.kick, "Started")
	}

}

internal class T_MyModule39 {
	
	static Void defineServices(ServiceDefinitions defs) {
		defs.add(T_MyService02#).withId("s2")
	}

	@Contribute
	static Void contributeRegistryStartup(Configuration config, T_MyService02 s2) {
		config.add |->| {
			s2.kick = "Started"
		}
	}
}
