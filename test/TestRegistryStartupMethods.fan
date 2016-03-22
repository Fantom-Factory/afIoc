using concurrent::AtomicRef

@Js
internal class TestRegistryStartupMethods : IocTest {

	Void testFuncsAddedViaConfig() {
		reg := RegistryBuilder().addModule(T_MyModule23#).build
		verifyEq("Hello!", T_MyModule23.ref.val)

		reg.shutdown
		verifyEq("Bye!", T_MyModule23.ref.val)
	}

	Void testFuncsCalledDirectly() {
		reg := RegistryBuilder().addModule(T_MyModule37#).build
		verifyEq("Hello!", T_MyModule37.ref.val)

		reg.shutdown
		verifyEq("Bye!", T_MyModule37.ref.val)
	}
}

@Js
internal const class T_MyModule23 {
	static const AtomicRef ref := AtomicRef(null)

	Void onRegistryStartup(Configuration config) {
		config["start"] = |->| {
			ref.val = "Hello!"
		}
	}

	Void onRegistryShutdown(Configuration config) {
		config["start"] = |->| {
			ref.val = "Bye!"
		}
	}
}

@Js
internal const class T_MyModule37 {
	static const AtomicRef ref := AtomicRef(null)

	// don't worry - these method calls are added to the config 
	Void onRegistryStartup() {
		ref.val = "Hello!"
	}

	// don't worry - these method calls are added to the config 
	Void onRegistryShutdown() {
		ref.val = "Bye!"
	}
}
