
internal class TestRegistryMethods : IocTest {

	Void testServiceById() {
		reg := RegistryBuilder().addModule(T_MyModule01#).build.startup
		T_MyService01 myService1 := reg.serviceById("t_myservice01")
		verifyEq(myService1.service.kick, "ASS!")
		verifySame(myService1, reg.serviceById("t_MyService01"))

		oops := reg.serviceById("oops", false)
		verifyNull(oops)
	}

	Void testDependencyByType() {
		reg := RegistryBuilder().addModule(T_MyModule01#).build.startup
		T_MyService01 myService1 := reg.dependencyByType(T_MyService01#)
		verifyEq(myService1.service.kick, "ASS!")
		verifySame(myService1, reg.dependencyByType(T_MyService01#))
		
		oops := reg.dependencyByType(Int#, false)
		verifyNull(oops)
	}

	Void testAutobuild() {
		reg := RegistryBuilder().addModule(T_MyModule01#).build.startup
		T_MyService01 myService1 := reg.autobuild(T_MyService01#)
		verifyEq(myService1.service.kick, "ASS!")
		verifyNotSame(myService1, reg.autobuild(T_MyService01#))
	}
	
	Void testInjectIntoFields() {
		reg := RegistryBuilder().addModule(T_MyModule01#).build.startup
		T_MyService01 myService1 := T_MyService01()
		verifyNull(myService1.service)
		reg.injectIntoFields(myService1)
		verifyEq(myService1.service.kick, "ASS!")
	}
}

internal class T_MyModule01 {
	static Void defineServices(ServiceDefinitions defs) {
		defs.add(T_MyService01#)
		defs.add(T_MyService02#)
	}
}

internal class T_MyService01 {
	@Inject
	T_MyService02? service
}

internal class T_MyService02 {
	Str kick	:= "ASS!"
}