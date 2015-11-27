
@Js
internal class TestFacetInject : IocTest {

	Void testFieldInjection() {
		reg := threadScope { addModule(T_MyModule34#) }

		// test field injection
		s65 := (T_MyService65) reg.serviceById("s65") 
		verifyNull(s65.opt2_1)
		verifyNull(s65.opt2_2)

		// test ctor injection
		s66 := (T_MyService66) reg.serviceById("s66") 
		verifyNull(s66.opt2_1)
		verifyNull(s66.opt2_2)
	}

	Void testFieldInjection2() {
		reg := threadScope { addModule(T_MyModule53#) }
		s33 := reg.serviceByType(T_MyService33#) as T_MyService33
		verifyEq(s33->impl1->wotcha, "Go1")
		verifyEq(s33->impl2->wotcha, "Go2")
	}

	Void testConstCtorInjection() {
		reg := threadScope { addModule(T_MyModule53#) }
		s35 := reg.serviceByType(T_MyService35#) as T_MyService35 
		verifyEq(s35->impl1->wotcha, "Go1")
		verifyEq(s35->impl2->wotcha, "Go2")
	}

	Void testServiceTypeMustMatch() {
		reg := threadScope { addModule(T_MyModule53#) }
		verifyIocErrMsg(ErrMsgs.dependencyProviders_dependencyDoesNotFit(T_MyService32Impl1#, T_MyService33?#)) {
			reg.serviceByType(T_MyService34#)			
		}
	}
}

// FUTURE: see http://fantom.org/sidewalk/topic/2186

//internal class TestInjectFacetInheritance : IocTest {
//		
//	Void testInjectIsInherited() {
//		t := (T_Class01) RegistryBuilder().build.autobuild(T_Class01#)
//		verifyNotNull(t.reg)
//		t.reg.shutdown
//	}	
//}
//
//internal mixin T_Mixin01 { 
//	@Inject
//	abstract Registry reg
//}
//
//internal class T_Class01 : T_Mixin01 {
//	override Registry reg
//	new make(|This|in) { in(this) }
//}

@Js
internal const class T_MyModule34 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService65#).withId("s65")
		defs.addService(T_MyService66#).withId("s66")
	}
}

@Js
internal class T_MyService65 {
	@Inject { optional=true }
	T_MyService02? opt2_1

	@Inject { optional=true; id="wotever" }
	T_MyService02? opt2_2
}

@Js
internal const class T_MyService66 {
	@Inject { optional=true }
	const T_MyService24? opt2_1

	@Inject { optional=true; id="wotever" }
	const T_MyService24? opt2_2
	
	new make(|This|in) { in(this) }
}

@Js
internal const class T_MyModule53 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService32#, T_MyService32Impl1#).withId("impl1")
		defs.addService(T_MyService32#, T_MyService32Impl2#).withId("impl2")
		defs.addService(T_MyService33#)
		defs.addService(T_MyService34#)
		defs.addService(T_MyService35#)
	}
}
@Js
internal const mixin T_MyService32 {
	abstract Str wotcha()
}
@Js
internal const class T_MyService32Impl1 : T_MyService32 {
	override const Str wotcha := "Go1"
}
@Js
internal const class T_MyService32Impl2 : T_MyService32 {
	override const Str wotcha := "Go2"
}

@Js
internal class T_MyService33 {
	@Inject { id = "impl1" }	Obj? impl1
	@Inject { id = "impl2" }	Obj? impl2
}
@Js
internal class T_MyService35 {
	@Inject { id = "impl1" }	const Obj? impl1
	@Inject { id = "impl2" }	const Obj? impl2
	new make(|This|di) { di(this) }
}
@Js
internal class T_MyService34 {	
	@Inject { id = "impl1" }
	T_MyService33? impl1
}