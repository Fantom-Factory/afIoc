
internal class TestRegistryShutdownHub : IocTest {
	
	Void testRegistryShutdownHub() {
		reg := RegistryBuilder().addModule(T_MyModule03#).build.startup
		T_MyService03 service := reg.serviceById("t_myservice03")
		reg.shutdown
		
		verify(service.called)
	}

}

internal class T_MyModule03 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService03#)
	}
}

internal const class T_MyService03 {
	private const ThreadStash 	stash	:= ThreadStash(typeof.name)
	
	Bool called {
		get { stash["called"] }
		set { stash["called"] = it }
	}
	
	new make(RegistryShutdownHub shutdownHub) {
		shutdownHub.addRegistryShutdownListener("T1", Str#.emptyList) |->| { called = true }
	}
}
