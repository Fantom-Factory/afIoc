using concurrent

internal class TestRegistryShutdownHub : IocTest {
	
	Void testRegistryShutdownHub() {
		RegistryBuilder().addModule(T_MyModule03#).build.startup.shutdown
		verifyEq(T_MyModule03.called.val, true)
	}

}

internal class T_MyModule03 {
	static const AtomicBool called	:= AtomicBool()

	@Contribute { serviceType=RegistryShutdown# }
	static Void contributeShutdown(Configuration config) {
		config.set("TestShutdown", |->| { called.val = true }).before("afIoc.shutdown")
	}
}
