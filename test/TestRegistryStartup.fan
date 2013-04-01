
class TestRegistryStartup : Test {
	
	Void testRegistryStartup() {
		Utils.setLoglevelDebug
		reg := RegistryBuilder().addModule(T_MyModule39#).build.startup
		T_MyService2 s2 := reg.serviceById("s2")
		verifyEq(s2.kick, "Started")
	}

}

internal class T_MyModule39 {
	
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService2#).withId("s2")
	}

	@Contribute
	static Void contributeRegistryStartup(OrderedConfig config, T_MyService2 s2) {
		config.addUnordered |->| {
			s2.kick = "Started"
		}
	}
}
