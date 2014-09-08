
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

	// FIXME autobuild service id
//	Void testAutoServiceId() {
//		reg := RegistryBuilder().addModule(T_MyModule55#).build.startup
//		s39 := (T_MyService39) reg.serviceById("s39")
//		verifyType(s39.ser2, T_MyService02#)
//		verifyNull(s39.ser12)
//	}
	
	Void testAutobuildHandlesNullableTypes() {
		reg := RegistryBuilder().addModule(T_MyModule55#).build.startup
		
		// the actual bug
		reg.autobuild(T_MyService59?#)
		
		// the actual usage
		reg.serviceById("s63")		
	}
}

internal class T_MyModule55 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService02#).withId("s2")
		binder.bind(T_MyService36#).withId("s36")
		binder.bind(T_MyService37#).withId("s37")
		binder.bind(T_MyService39#).withId("s39")
		binder.bind(T_MyService59#).withId("s59")
		binder.bind(T_MyService63#).withId("s63")
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

internal class T_MyService39 {
	// FIXME autobuild service id
//	@Autobuild { serviceId = "s2" }
//	T_MyService02? ser2	
//	@Autobuild { optional = true; serviceId = "s12" }
//	T_MyService12? ser12	
}

internal class T_MyService63 {
	@Autobuild
	T_MyService59? auto
}

internal class T_MyService59 {
	// BUGFIX: this ctor did break IoC
	new make(|This|in) { in(this) }
}
