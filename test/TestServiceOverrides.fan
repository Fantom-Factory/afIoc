
internal class TestServiceOverride : IocTest {

	Void testDupServiceIds() {
		confDef := SrvDef() {
			it.id 		= "wotever"
			it.moduleId = "wotever"
			it.buildData = T_MyModule07_b#buildAgain
		}
		existDef := SrvDef() {
			it.id 		= "wotever"
			it.moduleId = T_MyModule07#.qname
		}
		verifyErrMsg(IocErr#, IocMessages.serviceAlreadyDefined("s44", confDef, existDef)) {
			RegistryBuilder().addModule(T_MyModule07#).addModule(T_MyModule07_b#).build
		}
	}

	Void testOverrideSameServiceTwice() {
		confDef := SrvDef() {
			it.id 		= "wotever"
			it.moduleId = "wotever"
			it.buildData = T_MyModule50#overrideS44Again
		}
		existDef := SrvDef() {
			it.id 		= "wotever"
			it.moduleId = "wotever"
			it.buildData = T_MyModule50#overrideS44
		}
		verifyErrMsg(IocErr#, IocMessages.onlyOneOverrideAllowed("s44", confDef, existDef)) {
			RegistryBuilder().addModule(T_MyModule50#).build
		}
	}

	Void testDupOverrideIds() {
		confDef := SrvDef() {
			it.id 		= "wotever"
			it.moduleId = "wotever"
			it.buildData = T_MyModule59#overrideS44
		}
		existDef := SrvDef() {
			it.id 		= "wotever"
			it.moduleId = T_MyModule59#.qname
		}
		verifyErrMsg(IocErr#, IocMessages.overrideAlreadyDefined("taken", confDef, existDef)) {
			RegistryBuilder().addModule(T_MyModule59#).build
		}
	}

	Void testAppOverrideById() {
		Registry reg := RegistryBuilder().addModule(T_MyModule58#).build.startup
		s44 := (T_MyService44) reg.serviceById("s44")
		verify(s44 is T_MyService44Impl2)
		verifyEq(s44.judge, "dredd")
	}

	Void testAppOverrideByType() {
		Registry reg := RegistryBuilder().addModule(T_MyModule58#).build.startup
		s44 := (T_MyService44) reg.dependencyByType(T_MyService44#)
		verify(s44 is T_MyService44Impl2)
		verifyEq(s44.judge, "dredd")
	}

	Void testOverrideWrongType() {
		verifyIocErrMsg(IocMessages.serviceOverrideDoesNotFitServiceDef("s44", T_MyService12#, T_MyService44#)) {
			reg := RegistryBuilder().addModule(T_MyModule60#).build.startup
			T_MyService44 s44 := reg.serviceById("s44")
		}
	}

	Void testOverrideDoesNotExist() {
		verifyIocErrMsg(IocMessages.serviceIdNotFound("s12")) {
			RegistryBuilder().addModule(T_MyModule61#).build.startup
		}
	}
	
	Void testOverrideWorksWithNonQualifiedId() {
		Registry reg := RegistryBuilder().addModule(T_MyModule58#).build.startup
		s44 := (T_MyService44) reg.serviceById("T_MyService44")
		verify(s44 is T_MyService44Impl2)
		verifyEq(s44.judge, "dredd")		
	}

	Void testOverrideUsingTypeAsKey() {
		Registry reg := RegistryBuilder().addModule(T_MyModule58#).build.startup
		s90 := (T_MyService90) reg.dependencyByType(T_MyService90#)
		verify(s90 is T_MyService90Impl2)
		verifyEq(s90.judge, "dredd")
	}

	Void testOverrideByType() {
//		override in service defs
		reg := RegistryBuilder().addModule(T_MyModule58#).build.startup
		s45 := (T_MyService45) reg.serviceById("s45-type")
		verifyEq(s45.dude, "auto")
	}
}

internal class T_MyModule07 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService44#).withId("s44")
	}
}
internal class T_MyModule07_b {
	@Build { serviceId="s44" }
	static T_MyService44 buildAgain() {
		T_MyService44Impl()
	}
}

internal class T_MyModule50 {
	@Override { serviceId="s44" }
	static T_MyService44 overrideS44() {
		T_MyService44Impl()
	}
	@Override { serviceId="s44" }
	static T_MyService44 overrideS44Again() {
		T_MyService44Impl()
	}
}

internal class T_MyModule59 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService44#).withId("s44")
		binder.bind(T_MyService45#).withId("s45")
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

internal class T_MyModule58 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService44#).withId("s44").withoutProxy
		binder.bind(T_MyService44#).withoutProxy
		binder.bind(T_MyService90#).withoutProxy
		binder.bind(T_MyService45#).withId("s45-type").withScope(ServiceScope.perThread)
		binder.bind(T_MyService45#).withId("s45-func").withScope(ServiceScope.perThread)
	}

	@Override { serviceId = "s44" }
	static T_MyService44 overrideById(Registry reg) {
		reg.autobuild(T_MyService44Impl2#)
	}

	@Override
	static T_MyService44 overrideByType(Registry reg) {
		reg.autobuild(T_MyService44Impl2#)
	}

	@Override { serviceType=T_MyService90# }
	static T_MyService90 overrideUsingTypeAsKey(Registry reg) {
		reg.autobuild(T_MyService90Impl2#)
	}
}

internal const mixin T_MyService44 { virtual Str judge() { "anderson" } }
internal const class T_MyService44Impl  : T_MyService44 { }
internal const class T_MyService44Impl2 : T_MyService44 { override Str judge() { "dredd" } }

internal const mixin T_MyService90 { virtual Str judge() { "anderson" } }
internal const class T_MyService90Impl  : T_MyService90 { }
internal const class T_MyService90Impl2 : T_MyService90 { override Str judge() { "dredd" } }

@NoDoc mixin T_MyService45 {
	abstract Str? dude 
	virtual Str judge() { "anderson" } 
}
@NoDoc class T_MyService45Impl : T_MyService45 { 
	override Str? dude 
}
@NoDoc class T_MyService45Impl2 : T_MyService45 { 
	override Str? dude := "auto"
	override Str judge() { "dredd" } 
}

internal class T_MyModule60 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService44#).withId("s44")
		binder.bind(T_MyService12#).withId("s12")
	}

	@Override { serviceId="s44" }
	private static T_MyService12 overrideWotever() {
		(Obj) 69
	}	
}

internal class T_MyModule61 {
	@Override { serviceId="s12" }
	static T_MyService12 overrideWotever() {
		(Obj) 69
	}
}
