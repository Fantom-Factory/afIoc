
internal class TestCtorInjection : IocTest {
	
	Void testErrThrownWhenTooManyCtorsHaveTheInjectFacet() {
		verifyIocErrMsg(IocMessages.onlyOneCtorWithInjectFacetAllowed(T_MyService04#, 2)) { 
			RegistryBuilder().addModule(T_MyModule104#).build.startup
		}
	}

	Void testCorrectErrThrownWithWrongParams() {
		reg := RegistryBuilder().addModule(T_MyModule42#).build.startup
		verifyIocErrMsg(IocMessages.noDependencyMatchesType(T_MyService02#)) {
			reg.dependencyByType(T_MyService30#)
		}
	}

	Void testErrThrownWhenTooManyCtorsHaveTheSameNoOfParams() {
		verifyIocErrMsg(IocMessages.ctorsWithSameNoOfParams(T_MyService05#, 1)) {
			RegistryBuilder().addModule(T_MyModule105#).build.startup
		}
	}

	Void testCtorWithMostParamsIsPicked() {
		reg := RegistryBuilder().addModule(T_MyModule06#).build.startup
		verifyEq(reg.dependencyByType(T_MyService06#)->picked, "2 params" )
	}

	Void testCtorWithInjectFacetIsPicked() {
		reg := RegistryBuilder().addModule(T_MyModule06#).build.startup
		verifyEq(reg.dependencyByType(T_MyService07#)->picked, "1 param" )
	}

	Void testCtorWithFieldInjector() {
		reg := RegistryBuilder().addModule(T_MyModule06#).build.startup
		T_MyService08 ser8 := reg.dependencyByType(T_MyService08#)
		verifyEq(ser8.service2.kick, "ASS!" )
	}

	Void testFieldsAreNotInjectedTwice() {
		reg := RegistryBuilder().addModule(T_MyModule06#).build.startup
		T_MyService09 ser9 := reg.dependencyByType(T_MyService09#)
		verifyEq(ser9.service2.kick, "Can't Touch This!" )
	}
	
	Void testConstCtorInjectionForService() {
		reg := RegistryBuilder().addModule(T_MyModule42#).build.startup
		T_MyService25 s25 := reg.serviceById("s25")
		verifyEq(s25.s24.judge, "DREDD" )
	}

	Void testConstCtorInjectionForAutobuild() {
		reg := RegistryBuilder().addModule(T_MyModule42#).build.startup
		T_MyService25 s25 := reg.autobuild(T_MyService25#)
		verifyEq(s25.s24.judge, "DREDD" )
	}

	Void testConstCtorInjectionForAutobuildNullable() {
		reg := RegistryBuilder().addModule(T_MyModule42#).build.startup
		T_MyService26 s26 := reg.autobuild(T_MyService26#)
		verifyEq(s26.s24.judge, "DREDD" )
	}

	Void testTypeCreationWithNoCtor() {
		reg := RegistryBuilder().addModule(T_MyModule42#).build.startup
		reg.serviceById("s38")
	}
	
	Void testFieldNotSetErrIsConvertedToIocErr() {
		// this is such a common err we treat it as our own, to remove Ioc stack frames
		reg := RegistryBuilder().addModule(T_MyModule42#).build.startup
		verifyIocErrMsg(IocMessages.fieldNotSetErr(T_MyService53#judge.qname, T_MyService53#make)) {			
			reg.autobuild(T_MyService53#)
		}
	}
}

internal class T_MyModule104 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService04#)
	}	
}
internal class T_MyModule105 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService05#)
	}	
}

internal class T_MyModule06 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService01#)
		binder.bind(T_MyService02#)
		binder.bind(T_MyService06#)
		binder.bind(T_MyService07#)
		binder.bind(T_MyService08#)
		binder.bind(T_MyService09#)
	}
}

internal class T_MyService04 {
	@Inject
	new make1() { }
	@Inject
	new make2() { }
}

internal class T_MyService05 {
	new make1(T_MyService01 ser) { }
	new make2(T_MyService01 ser) { }
}

internal class T_MyService06 {
	Str picked
	new make0() { picked = "0 params" }
	new make1(T_MyService01 ser) { picked = "1 param" }
	new make2(T_MyService01 ser, T_MyService01 ser2) { picked = "2 params" }
}

internal class T_MyService07 {
	Str picked
	new make0() { picked = "0 params" }
	@Inject
	new make1(T_MyService01 ser) { picked = "1 param" }
	new make2(T_MyService01 ser, T_MyService01 ser2) { picked = "2 params" }
}

internal class T_MyService08 {
	@Inject
	T_MyService02 service2
	new make(|This| injectInto) { injectInto(this) }
}

internal class T_MyService09 {
	@Inject
	T_MyService02 service2
	new make(|This| injectInto) { 
		injectInto(this)
		// override the injector
		service2 = T_MyService02()
		service2.kick = "Can't Touch This!"
	}
}

internal class T_MyModule42 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService24#).withId("s24")
		binder.bind(T_MyService25#).withId("s25")
		binder.bind(T_MyService30#).withId("s30")
		binder.bind(T_MyService38#).withId("s38")
		binder.bind(T_MyService53#).withId("s53")
	}
}

internal const class T_MyService24 {
	const Str judge	:= "DREDD"
	new make(|This|in) { in(this) }
}

internal const class T_MyService25 {
	@Inject
	const T_MyService24 s24	
	new make(|This|in) { in(this) }
}

internal const class T_MyService26 {
	@Inject
	const T_MyService24 s24	
	new make(|This|in) { in(this) }
}

internal const class T_MyService30 {
	new make(T_MyService02 s2) { }
}

internal const class T_MyService38 { }

internal const class T_MyService53 {
	const Str judge
	new make(|This|in) { in(this) }
}