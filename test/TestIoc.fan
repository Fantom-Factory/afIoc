
class TestIoc : Test {

	Void testServiceById() {
		reg := RegistryBuilder().addType(T_MyModule1#).build.performRegistryStartup
		T_MyService1 myService1 := reg.serviceById("t_myservice1")
		verifyEq(myService1.service.kick, "ASS!")
		verifySame(myService1, reg.serviceById("t_MyService1"))
	}

	Void testServiceByType() {
		reg := RegistryBuilder().addType(T_MyModule1#).build.performRegistryStartup
		T_MyService1 myService1 := reg.serviceByType(T_MyService1#)
		verifyEq(myService1.service.kick, "ASS!")
		verifySame(myService1, reg.serviceByType(T_MyService1#))
	}

	Void testAutobuild() {
		reg := RegistryBuilder().addType(T_MyModule1#).build.performRegistryStartup
		T_MyService1 myService1 := reg.autobuild(T_MyService1#)
		verifyEq(myService1.service.kick, "ASS!")
		verifyNotSame(myService1, reg.autobuild(T_MyService1#))
	}
}

class T_MyModule1 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService1#)
		binder.bindImpl(T_MyService2#)
	}
}

class T_MyService1 {
	@Inject
	T_MyService2? service
}

class T_MyService2 {
	Str kick	:= "ASS!"
}