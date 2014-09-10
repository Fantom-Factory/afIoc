
internal class TestInjectFacetAutobuild : IocTest {
	
	Void testFieldInjection() {
		reg := RegistryBuilder().addModule(T_MyModule55#).build.startup
		s36 := reg.dependencyByType(T_MyService36#) as T_MyService36 
		s37 := reg.dependencyByType(T_MyService37#) as T_MyService37 
		verifySame(s36.ser2, s37.ser2)
		verifyNotSame(s36.auto2, s37.auto2)
		verifyNotSame(s36.ser2, s36.auto2)
		verifyNotSame(s37.ser2, s37.auto2)
	}

	Void testAutoServiceId() {
		reg := RegistryBuilder().addModule(T_MyModule55#).build.startup
		s39 := (T_MyService39) reg.serviceById("s39")

		verifyEq(s39.auto.typeof, T_MyService77Impl#)
		verifyEq(s39.auto.fromList, "auto-ctor")
		verifyEq(s39.auto.fromMap,  "auto-field")
	}
	
	Void testAutobuildHandlesNullableTypes() {
		reg := RegistryBuilder().addModule(T_MyModule55#).build.startup
		
		// the actual bug
		reg.autobuild(T_MyService59?#)
		
		// the actual usage
		reg.serviceById("s63")		
	}
}

internal class T_MyModule55 {
	static Void defineServices(ServiceDefinitions defs) {
		defs.add(T_MyService02#).withId("s2")
		defs.add(T_MyService36#).withId("s36")
		defs.add(T_MyService37#).withId("s37")
		defs.add(T_MyService63#).withId("s63")
		defs.add(T_MyService39#).withId("s39")
	}
}

internal class T_MyService36 {
	@Autobuild
	T_MyService02? auto2
	@Inject
	T_MyService02? ser2
}
internal class T_MyService37 {
	@Autobuild
	T_MyService02? auto2
	@Inject
	T_MyService02? ser2
}

internal class T_MyService63 {
	@Autobuild
	T_MyService59? auto
}

internal class T_MyService59 {
	// BUGFIX: this ctor did break IoC
	new make(|This|in) { in(this) }
}

internal class T_MyService39 {
	@Autobuild { ctorArgs=["auto-ctor"]; fieldVals=[T_MyService77#fromMap:"auto-field"]; implType=T_MyService77Impl#;  }
	T_MyService77? auto
	
	@Autobuild { ctorArgs=["proxy-ctor"]; fieldVals=[T_MyService77#fromMap:"proxy-field"]; createProxy=true }
	T_MyService77? proxy
}

@NoDoc mixin T_MyService77 {
	abstract Str fromList
	abstract Str fromMap
}

@NoDoc class T_MyService77Impl : T_MyService77 {
	override Str fromList
	override Str fromMap
	new make(Str fromList, |This|in) {
		this.fromList = fromList
		in(this) 
	}
}