
@Js
internal class TestFacetAutobuild : IocTest {
	
	Void testFieldInjection() {
		scope := threadScope { it.addModule(T_MyModule55#) }
		s36	  := scope.serviceByType(T_MyService36#) as T_MyService36 
		s37   := scope.serviceByType(T_MyService37#) as T_MyService37

		verifyNotNull(s36.ser2)
		verifyNotNull(s37.ser2)
		verifySame   (s36.ser2,  s37.ser2)
		verifyNotSame(s36.auto2, s37.auto2)
		verifyNotSame(s36.ser2,  s36.auto2)
		verifyNotSame(s37.ser2,  s37.auto2)
	}

	Void testAutoServiceId() {
		scope := threadScope { it.addModule(T_MyModule55#) }
		s39 := (T_MyService39) scope.serviceById("s39")

		verifyEq(s39.auto.typeof, T_MyService77#)
		verifyEq(s39.auto.fromList, "auto-ctor")
		verifyEq(s39.auto.fromMap,  "auto-field")
	}
	
	Void testAutobuildHandlesNullableTypes() {
		scope := threadScope { it.addModule(T_MyModule55#) }
		
		// the actual bug
		scope.build(T_MyService59?#)
		
		// the actual usage
		scope.serviceById("s63")		
	}
}

@Js
internal const class T_MyModule55 {
	static Void defineServices(RegistryBuilder bob) {
		bob.addService(T_MyService02#) { withId("s02") }
		bob.addService(T_MyService36#) { withId("s36") }
		bob.addService(T_MyService37#) { withId("s37") }
		bob.addService(T_MyService39#) { withId("s39") }
		bob.addService(T_MyService63#) { withId("s63") }
	}
}

@Js
internal class	T_MyService36 {
	@Autobuild	T_MyService02? auto2
	@Inject		T_MyService02? ser2
}
@Js
internal class	T_MyService37 {
	@Autobuild	T_MyService02? auto2
	@Inject		T_MyService02? ser2
}

@Js
internal class T_MyService39 {
	@Autobuild { ctorArgs=["auto-ctor"]; fieldVals=[T_MyService77#fromMap:"auto-field"] }
	T_MyService77? auto
}

@Js
internal class T_MyService59 {
	// BUGFIX: this ctor broke IoC
	new make(|This|in) { in(this) }
}

@Js
internal class	T_MyService63 {
	@Autobuild	T_MyService59? auto
}

@Js
internal class T_MyService77 {
	Str fromList
	Str fromMap
	new make(Str fromList, |This|in) {
		this.fromList = fromList
		in(this) 
	}
}
