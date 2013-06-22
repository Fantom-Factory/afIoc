
internal class TestRegistryStartup : IocTest {
	
	Void testRegistryStartup() {
		reg := RegistryBuilder().addModule(T_MyModule39#).build.startup
		T_MyService02 s2 := reg.serviceById("s2")
		verifyEq(s2.kick, "Started")
	}

}

internal class T_MyModule39 {
	
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService02#).withId("s2")
	}

	@Contribute
	static Void contributeRegistryStartup(OrderedConfig config, T_MyService02 s2) {
		config.addUnordered |->| {
			s2.kick = "Started"
		}
	}
}
