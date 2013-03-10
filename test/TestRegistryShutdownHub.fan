
class TestRegistryShutdownHub : Test {
	
	Void testRegistryShutdownHub() {
		reg := RegistryBuilder().addModule(T_MyModule3#).build.startup
		T_MyService3 service := reg.serviceById("t_myservice3")
		reg.shutdown
		
		verify(service.called)
	}
	
}

class T_MyModule3 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService3#)
	}
}

class T_MyService3 {
	Bool called
	new make(RegistryShutdownHub shutdownHub) {
		shutdownHub.addRegistryShutdownListener |->| { called = true; }
	}
}