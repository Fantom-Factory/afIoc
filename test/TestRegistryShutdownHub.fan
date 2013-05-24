
internal class TestRegistryShutdownHub : IocTest {
	
	Void testRegistryShutdownHub() {
		reg := RegistryBuilder().addModule(T_MyModule3#).build.startup
		T_MyService3 service := reg.serviceById("t_myservice3")
		reg.shutdown
		
		verify(service.called)
	}

}

internal class T_MyModule3 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService3#)
	}
}

internal const class T_MyService3 {
	private const LocalStash 	stash	:= LocalStash(typeof)
	
	Bool called {
		get { stash["called"] }
		set { stash["called"] = it }
	}
	
	new make(RegistryShutdownHub shutdownHub) {
		shutdownHub.addRegistryShutdownListener("T1", Str#.emptyList) |->| { called = true }
	}
}