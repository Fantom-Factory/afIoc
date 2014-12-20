
internal class TestServiceDefinitions : IocTest {

	Void testServiceDefWithArgs() {
		reg := RegistryBuilder().addModule(T_MyModule108#).build.startup
		ser := (T_MyService102) reg.serviceById("s102")
		verifyEq(ser.a, "Judge")
		verifyEq(ser.b, "Dredd")

		ovr := (T_MyService102) reg.serviceById("o102")
		verifyEq(ovr.a, "Sexy")
		verifyEq(ovr.b, "Anderson")
	}
}

internal class T_MyModule108 {
	static Void defineServices(ServiceDefinitions defs) {
		defs.add(T_MyService102#).withCtorArgs(["Judge"]).withFieldVals([T_MyService102#b:"Dredd"]).withId("s102")

		defs.add(T_MyService102#).withCtorArgs(["Judge"]).withFieldVals([T_MyService102#b:"Dredd"]).withId("o102")
		defs.overrideById("o102").withCtorArgs(["Sexy" ]).withFieldVals([T_MyService102#b:"Anderson"])
	}
}

internal class T_MyService102 {
	Str a
	Str b
	new make(Str a, |This|f) {
		f(this)
		this.a = a
	}
}