
internal class TestInjectFacetOptional : IocTest {

	Void testFieldInjection() {
		reg := RegistryBuilder().addModule(T_MyModule34#).build.startup

		// test field injection
		s65 := (T_MyService65) reg.serviceById("s65") 
		verifyNull(s65.opt2_1)
		verifyNull(s65.opt2_2)

		// test ctor injection
		s66 := (T_MyService66) reg.serviceById("s66") 
		verifyNull(s66.opt2_1)
		verifyNull(s66.opt2_2)
	}
}

internal class T_MyModule34 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService65#).withId("s65")
		binder.bind(T_MyService66#).withId("s66")
	}
}

internal class T_MyService65 {
	@Inject { optional=true }
	T_MyService02? opt2_1

	@Inject { optional=true; serviceId="wotever" }
	T_MyService02? opt2_2
}

internal const class T_MyService66 {
	@Inject { optional=true }
	const T_MyService24? opt2_1

	@Inject { optional=true; serviceId="wotever" }
	const T_MyService24? opt2_2
	
	new make(|This|in) { in(this) }
}
