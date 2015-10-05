
internal class TestServiceOverride : IocTest {

	Void testDupServiceIds() {
		verifyErrMsg(IocErr#, ErrMsgs.regBuilder_serviceAlreadyDefined("s44", T_MyModule07_b#, T_MyModule07#)) {
			threadScope { addModule(T_MyModule07#); addModule(T_MyModule07_b#) }
		}
	}

	Void testOverrideSameServiceTwice() {
		verifyErrMsg(IocErr#, ErrMsgs.regBuilder_onlyOneOverrideAllowed("s44", T_MyModule50#, T_MyModule50#)) {
			RegistryBuilder().addModule(T_MyModule50#).build
		}
	}

	Void testDupOverrideIds() {
		verifyErrMsg(IocErr#, ErrMsgs.regBuilder_overrideAlreadyDefined("taken", T_MyModule59#, T_MyModule59#)) {
			RegistryBuilder().addModule(T_MyModule59#).build
		}
	}

	Void testAppOverrideById() {
		reg := threadScope { addModule(T_MyModule58#) }
		s44 := (T_MyService44) reg.serviceById("s44")
		verify(s44 is T_MyService44Impl2)
		verifyEq(s44.judge, "dredd")
	}

	Void testAppOverrideByType() {
		reg := threadScope { addModule(T_MyModule58#) }
		s44 := (T_MyService56) reg.serviceByType(T_MyService56#)
		verify(s44 is T_MyService56Impl2)
		verifyEq(s44.judge, "dredd")
	}

	Void testOverrideWrongType() {
		verifyIocErrMsg(ErrMsgs.autobuilder_bindImplDoesNotFit(T_MyService44#, T_MyService02#)) {
			reg := threadScope { addModule(T_MyModule60#) }
			s44 := (T_MyService44) reg.serviceById("s44")
		}
	}

	Void testOverrideDoesNotExist() {
		verifySrvNotFoundErrMsg(ErrMsgs.regBuilder_serviceIdNotFound("s12")) {
			reg := threadScope { addModule(T_MyModule61#) }
		}
	}

	Void testOverrideUsingTypeAsKey() {
		reg := threadScope { addModule(T_MyModule58#) }
		s90 := (T_MyService90) reg.serviceByType(T_MyService90#)
		verify(s90 is T_MyService90Impl2)
		verifyEq(s90.judge, "dredd")
	}

	Void testOverrideByType() {
		reg := threadScope { addModule(T_MyModule58#) }
		s45 := (T_MyService45) reg.serviceById("s45-type")
		verifyEq(s45.dude, "auto")
	}
}

internal const class T_MyModule07 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService44#).withId("s44")
	}
}
internal const class T_MyModule07_b {
	@Build { serviceId="s44" }
	static T_MyService44 buildAgain() {
		T_MyService44Impl()
	}
}

internal const class T_MyModule50 {
	@Override { serviceId="s44" }
	static T_MyService44 overrideS44() {
		T_MyService44Impl()
	}
	@Override { serviceId="s44" }
	static T_MyService44 overrideS44Again() {
		T_MyService44Impl()
	}
}

internal const class T_MyModule59 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService44#).withId("s44")
		defs.addService(T_MyService45#).withId("s45")
	}
	@Override { serviceId="s44"; overrideId="taken" }
	static T_MyService44 overrideS44() {
		T_MyService44Impl()
	}
	@Override { serviceId="s45"; overrideId="taken"  }
	static T_MyService45 overrideS45() {
		T_MyService45Impl()
	}
}

internal const class T_MyModule58 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService44#).withId("s44")
		defs.addService(T_MyService56#)
		defs.addService(T_MyService90#)
		defs.addService(T_MyService45#).withId("s45-type").withScopes(["thread"])
		defs.addService(T_MyService45#).withId("s45-func").withScopes(["thread"])
		defs.overrideService("s45-type").withImplType(T_MyService45Impl2#)
	}

	@Override { serviceId = "s44" }
	static T_MyService44 overrideById(Scope reg) {
		reg.build(T_MyService44Impl2#)
	}

	@Override
	static T_MyService56 overrideByType(Scope reg) {
		reg.build(T_MyService56Impl2#)
	}

	@Override { serviceType=T_MyService90# }
	static T_MyService90 overrideUsingTypeAsKey(Scope reg) {
		reg.build(T_MyService90Impl2#)
	}
}

internal const mixin T_MyService44 { virtual Str judge() { "anderson" } }
internal const class T_MyService44Impl  : T_MyService44 { }
internal const class T_MyService44Impl2 : T_MyService44 { override Str judge() { "dredd" } }

internal const mixin T_MyService56 { virtual Str judge() { "anderson" } }
internal const class T_MyService56Impl2 : T_MyService56 { override Str judge() { "dredd" } }

internal const mixin T_MyService90 { virtual Str judge() { "anderson" } }
internal const class T_MyService90Impl  : T_MyService90 { }
internal const class T_MyService90Impl2 : T_MyService90 { override Str judge() { "dredd" } }

internal mixin T_MyService45 {
	abstract Str? dude 
	virtual Str judge() { "anderson" } 
}
internal class T_MyService45Impl : T_MyService45 { 
	override Str? dude 
}
internal class T_MyService45Impl2 : T_MyService45 { 
	override Str? dude := "auto"
	override Str judge() { "dredd" } 
}

internal const class T_MyModule60 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService44#).withId("s44")
		defs.addService(T_MyService02#).withId("s12")
	}

	@Override { serviceId="s44" }
	private static T_MyService02 overrideWotever() {
		T_MyService02()
	}	
}

internal const class T_MyModule61 {
	@Override { serviceId="s12" }
	static T_MyService02 overrideWotever() {
		T_MyService02()
	}
}
