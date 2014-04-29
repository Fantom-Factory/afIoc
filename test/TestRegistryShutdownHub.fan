using afConcurrent::LocalRef

internal class TestRegistryShutdownHub : IocTest {
	
	Void testRegistryShutdownHub() {
		reg := RegistryBuilder().addModule(T_MyModule03#).build.startup
		service := (T_MyService03) reg.serviceById("t_myservice03")
		reg.shutdown
		
		verifyEq(service.called.val, true)
	}

}

internal class T_MyModule03 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService03#)
	}
}

internal const class T_MyService03 {
	const LocalRef 	called	:= LocalRef(typeof.name)
	
	new make(RegistryShutdownHub shutdownHub) {
		shutdownHub.addRegistryShutdownListener("T1", Str#.emptyList) |->| { called.val = true }
	}
}
