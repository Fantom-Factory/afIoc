
@Js
internal class TestRecursion : IocTest {
	
	Void testModulesCantBeAddedTwice() {
		RegistryBuilder() {
			addScope("thread", true)
			addModule(T_MyModule20#)
			addModule(T_MyModule20#) 
		}.build
	}
	
	Void testErrOnRecursiveInjection1() {
		reg := threadScope { addModule(T_MyModule20#) }
		verifyIocErrMsg(ErrMsgs.scope_serviceRecursion("s15", ["s15", "s15"])) { 
			reg.serviceById("s15") 
		}
	}

	Void testErrOnRecursiveInjection2() {
		reg := threadScope { addModule(T_MyModule20#) }
		verifyIocErrMsg(ErrMsgs.scope_serviceRecursion("s16", ["s16", "s17", "s16"])) { 
			reg.serviceById("s16") 
		}
	}

	Void testErrOnRecursiveInjection3() {
		reg := threadScope { addModule(T_MyModule20#) }
		verifyIocErrMsg(ErrMsgs.scope_serviceRecursion("s17", ["s18", "s17", "s16", "s17"])) { 
			reg.serviceById("s18") 
		}
	}

	Void testBuilderMethodRecursion() {
		reg := threadScope { addModule(T_MyModule102#) }
		verifyIocErrMsg(ErrMsgs.scope_serviceRecursion("s101", ["s101", "s100", "s101"])) { 
			reg.serviceById("s101") 
		}
	}
}


@Js
internal const class T_MyModule20 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService15#).withId("s15")
		defs.addService(T_MyService16#).withId("s16")
		defs.addService(T_MyService17#).withId("s17")
		defs.addService(T_MyService18#).withId("s18")
	}
}

@Js
internal class T_MyService15 {
	@Inject	T_MyService15? ser
}

@Js
internal class T_MyService16 {
	@Inject	T_MyService17? ser
}

@Js
internal class T_MyService17 {
	@Inject	T_MyService16 ser
	new make(|This|in) { in(this) }
}

@Js
internal class T_MyService18 {
	@Inject	T_MyService17 ser
	new make(|This|in) { in(this) }
}

@Js
internal const class T_MyModule102 {
	@Build { serviceId="s100" }
	static T_MyService100 buildS100(T_MyService101 s101) { T_MyService100() }
	@Build { serviceId="s101" }
	static T_MyService101 buildS101(T_MyService100 s100) { T_MyService101() }
}
@Js
internal const class T_MyService100 { }
@Js
internal const class T_MyService101 { }
