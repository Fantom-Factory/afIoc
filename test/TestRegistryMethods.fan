
internal class TestRegistryMethods : IocTest {

	Void testServiceById() {
		reg := RegistryBuilder().addModule(T_MyModule1#).build.startup
		T_MyService1 myService1 := reg.serviceById("t_myservice1")
		verifyEq(myService1.service.kick, "ASS!")
		verifySame(myService1, reg.serviceById("t_MyService1"))
	}

	Void testDependencyByType() {
		reg := RegistryBuilder().addModule(T_MyModule1#).build.startup
		T_MyService1 myService1 := reg.dependencyByType(T_MyService1#)
		verifyEq(myService1.service.kick, "ASS!")
		verifySame(myService1, reg.dependencyByType(T_MyService1#))
	}

	Void testAutobuild() {
		reg := RegistryBuilder().addModule(T_MyModule1#).build.startup
		T_MyService1 myService1 := reg.autobuild(T_MyService1#)
		verifyEq(myService1.service.kick, "ASS!")
		verifyNotSame(myService1, reg.autobuild(T_MyService1#))
	}
	
	Void testInjectIntoFields() {
		reg := RegistryBuilder().addModule(T_MyModule1#).build.startup
		T_MyService1 myService1 := T_MyService1()
		verifyNull(myService1.service)
		reg.injectIntoFields(myService1)
		verifyEq(myService1.service.kick, "ASS!")
	}
}

internal class T_MyModule1 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService1#)
		binder.bindImpl(T_MyService2#)
	}
}

internal class T_MyService1 {
	@Inject
	T_MyService2? service
}

internal class T_MyService2 {
	Str kick	:= "ASS!"
}