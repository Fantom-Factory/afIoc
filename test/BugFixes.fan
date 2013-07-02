using concurrent::Actor
using concurrent::ActorPool

internal class BugFixes : IocTest {
	
	Void testProxiedServicesAreStillThreadScoped() {
		Registry reg := RegistryBuilder().addModule(T_MyModule83#).build.startup
		
		stats1	:= reg.serviceById(ServiceIds.serviceStats) as ServiceStats
		
		assertEqual(stats1.stats["t50"].lifecycle, ServiceLifecycle.DEFINED)
		t50_1 := reg.serviceById("t50")
		assertEqual(stats1.stats["t50"].lifecycle, ServiceLifecycle.VIRTUAL)
		t50_1->dude
		assertEqual(stats1.stats["t50"].lifecycle, ServiceLifecycle.CREATED)

		Actor(ActorPool()) |->| {
			stats2	:= reg.serviceById(ServiceIds.serviceStats) as ServiceStats			

			// as we're in a new thread, ensure the service has it's own lifecycle
			assertEqual(stats2.stats["t50"].lifecycle, ServiceLifecycle.DEFINED)
			t50_2 := reg.serviceById("t50")
			assertEqual(stats2.stats["t50"].lifecycle, ServiceLifecycle.VIRTUAL)
			t50_2->dude
			assertEqual(stats2.stats["t50"].lifecycle, ServiceLifecycle.CREATED)
			
		}.send(null).get
	}

	Void testProxiedServicesAreCachedOnceCreated_perThread() {
		Registry reg := RegistryBuilder().addModule(T_MyModule83#).build.startup

		t50_1 	 := reg.serviceById("t50-thread")
		proxyPod := t50_1.typeof.pod

		t50_1 -> dude
		t50_1 = reg.serviceById("t50-thread")
		
		// once the service is created, it should no longer be in the proxy pod
		verifyNotEq(t50_1.typeof.pod, proxyPod)
	}

	Void testProxiedServicesAreCachedOnceCreated_perApplication() {
		Registry reg := RegistryBuilder().addModule(T_MyModule83#).build.startup

		t50_1 	 := reg.serviceById("t50-app")
		proxyPod := t50_1.typeof.pod

		t50_1 -> dude
		t50_1 = reg.serviceById("t50-app")

		// once the service is created, it should no longer be in the proxy pod
		verifyNotEq(t50_1.typeof.pod, proxyPod)
	}
	
	Void testOrderedPlaceholdersAllowedOnNonStrConfig() {
		Registry reg 		:= RegistryBuilder().addModule(T_MyModule85#).build.startup
		T_MyService70 t70	:= reg.serviceById("t70")
		verifyNotNull(t70)
	}
	
	static Void assertEqual(Obj? o1, Obj? o2) {
		if (o1 != o2)
			throw Err("Are NOT equal - $o1 : $o2")
	}
}

internal class T_MyModule83 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(PublicTestTypes.type("T_MyService50")).withId("t50").withScope(ServiceScope.perThread)
		binder.bindImpl(PublicTestTypes.type("T_MyService50")).withId("t50-thread").withScope(ServiceScope.perThread)
		binder.bindImpl(PublicTestTypes.type("T_MyService50")).withId("t50-app").withScope(ServiceScope.perApplication)
	}
}

internal class T_MyModule85 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService70#).withId("t70")
	}
	
	@Contribute
	static Void contributeT70(OrderedConfig config) {
		config.addOrderedPlaceholder("routes")		
		config.addOrdered("key69", 69, ["before: routes"])
	}
}

internal class T_MyService70 {
	new make(Int[] config) { }
}
