
class TestIoc : Test {

	Void testServiceById() {
		reg := RegistryBuilder().addType(MyModule#).build.performRegistryStartup
		MyService1 myService1 := reg.serviceById("myservice1")
		verifyEq(myService1.service.kick, "ASS!")
		verifySame(myService1, reg.serviceById("myservice1"))
	}

	Void testServiceByType() {
		reg := RegistryBuilder().addType(MyModule#).build.performRegistryStartup
		MyService1 myService1 := reg.serviceByType(MyService1#)
		verifyEq(myService1.service.kick, "ASS!")
		verifySame(myService1, reg.serviceByType(MyService1#))
	}

	Void testAutobuild() {
		reg := RegistryBuilder().addType(MyModule#).build.performRegistryStartup
		MyService1 myService1 := reg.autobuild(MyService1#)
		verifyEq(myService1.service.kick, "ASS!")
		verifyNotSame(myService1, reg.autobuild(MyService1#))
	}
}

class MyModule {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(MyService1#)
		binder.bindImpl(MyService2#)
	}
}

class MyService1 {
	@Inject
	MyService2? service
}

class MyService2 {
	Str kick	:= "ASS!"
}