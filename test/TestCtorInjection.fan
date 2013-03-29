
class TestCtorInjection : Test {
	
	Void testErrThrownWhenTooManyCtorsHaveTheInjectFacet() {
		reg := RegistryBuilder().addModule(T_MyModule6#).build.startup
		verifyErr(IocErr#) { reg.dependencyByType(T_MyService4#) }
	}

	Void testErrThrownWhenTooManyCtorsHaveTheSameNoOfParams() {
		reg := RegistryBuilder().addModule(T_MyModule6#).build.startup
		verifyErr(IocErr#) { reg.dependencyByType(T_MyService5#) }
	}

	Void testCtorWithMostParamsIsPicked() {
		Utils.setLoglevelDebug
		reg := RegistryBuilder().addModule(T_MyModule6#).build.startup
		Utils.setLoglevelInfo
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
