
class TestCtorInjection : IocTest {
	
	Void testErrThrownWhenTooManyCtorsHaveTheInjectFacet() {
		reg := RegistryBuilder().addModule(T_MyModule6#).build.startup
		verifyErrMsg(IocMessages.onlyOneCtorWithInjectFacetAllowed(T_MyService4#, 2)) { 
			reg.dependencyByType(T_MyService4#) 
		}
	}

	Void testCorrectErrThrownWithWrongParams() {
		reg := RegistryBuilder().addModule(T_MyModule42#).build.startup
		verifyErrMsg(IocMessages.noDependencyMatchesType(T_MyService3#)) {
			reg.dependencyByType(T_MyService30#)
		}
	}

	Void testErrThrownWhenTooManyCtorsHaveTheSameNoOfParams() {
		reg := RegistryBuilder().addModule(T_MyModule6#).build.startup
		verifyErrMsg(IocMessages.ctorsWithSameNoOfParams(T_MyService5#, 1)) { 
			reg.dependencyByType(T_MyService5#) 
		}
	}

	Void testCtorWithMostParamsIsPicked() {
		reg := RegistryBuilder().addModule(T_MyModule6#).build.startup
		verifyEq(reg.dependencyByType(T_MyService6#)->picked, "2 params" )
	}

	Void testCtorWithInjectFacetIsPicked() {
		reg := RegistryBuilder().addModule(T_MyModule6#).build.startup
		verifyEq(reg.dependencyByType(T_MyService7#)->picked, "1 param" )
	}

	Void testCtorWithFieldInjector() {
		reg := RegistryBuilder().addModule(T_MyModule6#).build.startup
		T_MyService8 ser8 := reg.dependencyByType(T_MyService8#)
		verifyEq(ser8.service2.kick, "ASS!" )
	}

	Void testFieldsAreNotInjectedTwice() {
		reg := RegistryBuilder().addModule(T_MyModule6#).build.startup
		T_MyService9 ser9 := reg.dependencyByType(T_MyService9#)
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
	
}

internal class T_MyModule6 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService1#)
		binder.bindImpl(T_MyService2#)
		binder.bindImpl(T_MyService4#)
		binder.bindImpl(T_MyService5#)
		binder.bindImpl(T_MyService6#)
		binder.bindImpl(T_MyService7#)
		binder.bindImpl(T_MyService8#)
		binder.bindImpl(T_MyService9#)
	}
}

internal class T_MyService4 {
	@Inject
	new make1() { }
	@Inject
	new make2() { }
}

internal class T_MyService5 {
	new make1(T_MyService1 ser) { }
	new make2(T_MyService1 ser) { }
}

internal class T_MyService6 {
	Str picked
	new make0() { picked = "0 params" }
	new make1(T_MyService1 ser) { picked = "1 param" }
	new make2(T_MyService1 ser, T_MyService1 ser2) { picked = "2 params" }
}

internal class T_MyService7 {
	Str picked
	new make0() { picked = "0 params" }
	@Inject
	new make1(T_MyService1 ser) { picked = "1 param" }
	new make2(T_MyService1 ser, T_MyService1 ser2) { picked = "2 params" }
}

internal class T_MyService8 {
	@Inject
	T_MyService2 service2
	new make(|This| injectInto) { injectInto(this) }
}

internal class T_MyService9 {
	@Inject
	T_MyService2 service2
	new make(|This| injectInto) { 
		injectInto(this)
		// override the injector
		service2 = T_MyService2()
		service2.kick = "Can't Touch This!"
	}
}

internal class T_MyModule42 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService24#).withId("s24")
		binder.bindImpl(T_MyService25#).withId("s25")
		binder.bindImpl(T_MyService30#).withId("s30")
	}
}

internal const class T_MyService24 {
	const Str judge	:= "DREDD"
//	new make(FieldInjector inject) { inject.into()(this) }
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
	new make(T_MyService3 ser3) { }
}
