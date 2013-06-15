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

	static Void assertEqual(Obj? o1, Obj? o2) {
		if (o1 != o2)
			throw Err("Are NOT equal - $o1 : $o2")
	}
}

internal class T_MyModule83 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService69#).withId("the")
		binder.bindImpl(PublicTestTypes.type("T_MyService50")).withId("t50").withScope(ServiceScope.perThread)
	}
}

internal class T_MyService69 {
	@Inject @ServiceId { serviceId="t50" } 
	Obj? t50
}


