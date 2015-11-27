
@Js
internal class TestCtorInjection : IocTest {
	
	Void testErrThrownWhenTooManyCtorsHaveTheInjectFacet() {
		verifyIocErrMsg(ErrMsgs.autobuilder_ctorsWithSameNoOfParams(T_MyService04#, 0)) {
			scope := rootScope { it.addService(T_MyService04#) }
			scope.serviceByType(T_MyService04#)
		}
	}

	Void testCorrectErrThrownWithWrongParams() {
		verifyIocErrMsg(ErrMsgs.autobuilder_couldNotFindAutobuildCtor(T_MyService30#, null)) {
			scope := rootScope { it.addService(T_MyService30#) { withId("s30") } }
			scope.serviceByType(T_MyService30#)
		}
	}

	Void testErrThrownWhenTooManyCtorsHaveTheSameNoOfParams() {
		verifyIocErrMsg(ErrMsgs.autobuilder_ctorsWithSameNoOfParams(T_MyService05#, 1)) {
			scope := threadScope { 
				addService(T_MyService01#) 
				addService(T_MyService05#).withScope("thread")	// const classes don't automatically match thread scopes		
			}
			scope.serviceByType(T_MyService05#)
		}
	}

	Void testCtorWithMostParamsIsPicked() {
		scope := threadScope { addModule(T_MyModule06#) }
		verifyEq(scope.serviceByType(T_MyService06#)->picked, "2 params" )
	}

	Void testCtorWithInjectFacetIsPicked() {
		scope := threadScope { addModule(T_MyModule06#) }
		verifyEq(scope.serviceByType(T_MyService07#)->picked, "1 param" )
	}

	Void testCtorWithFieldInjector() {
		scope := threadScope { addModule(T_MyModule06#) }
		s08   := (T_MyService08) scope.serviceByType(T_MyService08#)
		verifyEq(s08.service2.kick, "ASS!" )
	}

	Void testFieldsAreNotInjectedTwice() {
		scope := threadScope { addModule(T_MyModule06#) }
		s09   := (T_MyService09) scope.serviceByType(T_MyService09#)
		verifyEq(s09.service2.kick, "Can't Touch This!" )
	}
	
	Void testConstCtorInjectionForService() {
		scope := threadScope { addModule(T_MyModule42#) }
		s25   := (T_MyService25) scope.serviceById("s25")
		verifyEq(s25.s24.judge, "DREDD" )
	}

	Void testConstCtorInjectionForAutobuild() {
		scope := threadScope { addModule(T_MyModule42#) }
		s25   := (T_MyService25) scope.build(T_MyService25#)
		verifyEq(s25.s24.judge, "DREDD" )
	}

	Void testConstCtorInjectionForAutobuildNullable() {
		scope := threadScope { addModule(T_MyModule42#) }
		s26   := (T_MyService26) scope.build(T_MyService26#)
		verifyEq(s26.s24.judge, "DREDD" )
	}

	Void testTypeCreationWithNoCtor() {
		scope := threadScope { addModule(T_MyModule42#) }
		scope.serviceById("s38")
	}

	Void testNullableCtorTypesAreOptional() {
		s108 := (T_MyService108) rootScope.build(T_MyService108#)
		verifyNull(s108.judge)
	}
}

@Js
internal const class T_MyModule06 {
	Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService01#)
		defs.addService(T_MyService02#)
		defs.addService(T_MyService06#)
		defs.addService(T_MyService07#)
		defs.addService(T_MyService08#)
		defs.addService(T_MyService09#)
	}
}

@Js
internal const class T_MyService04 {
	@Inject	new make1() { }
	@Inject	new make2() { }
}

@Js
internal const class T_MyService05 {
	new make1(T_MyService01 ser) { }
	new make2(T_MyService01 ser) { }
}

@Js
internal class T_MyService06 {
	Str picked
	new make0() { picked = "0 params" }
	new make1(T_MyService01 ser) { picked = "1 param" }
	new make2(T_MyService01 ser, T_MyService01 ser2) { picked = "2 params" }
}

@Js
internal class T_MyService07 {
	Str picked
	new make0() { picked = "0 params" }
	@Inject
	new make1(T_MyService01 ser) { picked = "1 param" }
	new make2(T_MyService01 ser, T_MyService01 ser2) { picked = "2 params" }
}

@Js
internal class T_MyService08 {
	@Inject	T_MyService02 service2
	new make(|This| in) { in(this) }
}

@Js
internal class T_MyService09 {
	@Inject	T_MyService02 service2
	new make(|This| in) { 
		in(this)
		// override the injector
		service2.kick = "Can't Touch This!"
	}
}

@Js
internal const class T_MyModule42 {
	Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService24#) { withId("s24") }
		defs.addService(T_MyService25#) { withId("s25") }
		defs.addService(T_MyService38#) { withId("s38") }
		defs.addService(T_MyService53#) { withId("s53") }
	}
}

@Js
internal const class T_MyService24 {
	const Str judge	:= "DREDD"
	new make(|This|in) { in(this) }
}

@Js
internal const class T_MyService25 {
	@Inject	const T_MyService24 s24	
	new make(|This|in) { in(this) }
}

@Js
internal const class T_MyService26 {
	@Inject	const T_MyService24 s24	
	new make(|This|in) { in(this) }
}

@Js
internal const class T_MyService30 {
	new make(T_MyService02 s2) { }
}

@Js
internal const class T_MyService38 { }

@Js
internal const class T_MyService53 {
	const Str judge
	new make(|This|in) { in(this) }
}

@Js
internal const class T_MyService108 {
	const Str? judge
	const Registry reg
	new make(Str? judge, Registry reg) { this.judge = judge; this.reg = reg }
}