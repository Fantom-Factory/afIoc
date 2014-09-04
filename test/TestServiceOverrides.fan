
internal class TestServiceOverride : IocTest {

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
		verifyIocErrMsg(IocMessages.serviceOverrideDoesNotExist("s12")) {
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
		reg := RegistryBuilder().addModule(T_MyModule58#).build.startup
		s45 := (T_MyService45) reg.serviceById("s45-type")
		verifyEq(s45.dude, "auto")
	}

	Void testOverrideByFunc() {
		reg := RegistryBuilder().addModule(T_MyModule58#).build.startup
		s45 := (T_MyService45) reg.serviceById("s45-func")
		verifyEq(s45.dude, "funcy")
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

	@Build { serviceId = "s44" }
	static T_MyService44 overrideById(Registry reg) {
		reg.autobuild(T_MyService44Impl2#)
	}
	
	@Contribute { serviceType=ServiceOverrides# }
	private static Void contributeServiceOverrides(Configuration config) {
//		config["s44"] = config.autobuild(T_MyService44Impl2#)
		config["T_MyService44"] = T_MyService44Impl2()
		config[T_MyService90#] = T_MyService90Impl2()
		
		// override with type
		config["s45-type"] = T_MyService45Impl2#
		
		// override with func
		config["s45-func"] = |->Obj| { s := T_MyService45Impl2(); s.dude = "funcy"; return s }
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
	@Contribute { serviceType=ServiceOverrides# }
	private static Void contributeServiceOverrides(Configuration config) {
		config.set("s44", config.autobuild(T_MyService12#))
	}
}

internal class T_MyModule61 {
	@Contribute { serviceType=ServiceOverrides# }
	private static Void contributeServiceOverrides(Configuration config) {
		config.set("s12", config.autobuild(T_MyService12#))
	}
}
