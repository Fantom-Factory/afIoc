using concurrent::Actor
using concurrent::ActorPool

internal class BugFixes : IocTest {
	
	Void testProxiedServicesAreStillThreadScoped() {
		Registry reg := RegistryBuilder().addModule(T_MyModule83#).build.startup
		
		assertEqual(reg.serviceDefinitions["t50"].lifecycle, ServiceLifecycle.defined)
		t50_1 := reg.serviceById("t50")
		assertEqual(reg.serviceDefinitions["t50"].lifecycle, ServiceLifecycle.proxied)
		t50_1->dude
		assertEqual(reg.serviceDefinitions["t50"].lifecycle, ServiceLifecycle.created)

		Actor(ActorPool()) |->| {
			stats2	:= reg.serviceDefinitions

			// as we're in a new thread, ensure the service has it's own lifecycle
			assertEqual(reg.serviceDefinitions["t50"].lifecycle, ServiceLifecycle.defined)
			t50_2 := reg.serviceById("t50")
			assertEqual(reg.serviceDefinitions["t50"].lifecycle, ServiceLifecycle.proxied)
			t50_2->dude
			assertEqual(reg.serviceDefinitions["t50"].lifecycle, ServiceLifecycle.created)
			
		}.send(null).get
	}

	Void testOrderedPlaceholdersAllowedOnNonStrConfig() {
		Registry reg 		:= RegistryBuilder().addModule(T_MyModule85#).build.startup
		T_MyService70 t70	:= reg.serviceById("t70")
		verifyNotNull(t70)
	}

	// A service is proxied for a reason, usually so a threaed one can be injected into an app one, if we start 
	// returning the real service, the whole point of having a proxy is lost! (Oh, and the app crashes!)
	Void testProxiedServicesStayProxied() {
		reg := RegistryBuilder().addModule(T_MyModule85#).build.startup
		
		// grab a proxied service
		t85	:= (T_MyService85) reg.serviceById("t85")

		// ensure the it's a proxy (not the real impl)
		verifyNotEq(t85.typeof, T_MyService85Impl#)
		
		// realise the service
		t85.judge
		
		// grab the service again 
		t85	= (T_MyService85) reg.serviceById("t85")
		
		// ensure the proxy is returned once again
		verifyNotEq(t85.typeof, T_MyService85Impl#)
	}
	
	static Void assertEqual(Obj? o1, Obj? o2) {
		if (o1 != o2)
			throw Err("Are NOT equal - $o1 : $o2")
	}

	Void testDupServiceCanBeGottenByType() {
		reg := RegistryBuilder().addModule(T_MyModule98#).build.startup
		
		s1 := reg.serviceById(T_MyService89#.qname)
		s2 := reg.serviceById("PillowRoutes")
		
		t1 := reg.serviceById("T_MyService89")
		verifyEq(t1, s1)

		t2 := reg.dependencyByType(T_MyService89#)
		verifyEq(t1, s1)
	}
	
	Void testThreadedServicesCanBeAutobuiltInCtor() {
		reg := RegistryBuilder().addModule(T_MyModule100#).build.startup
		t2 := reg.serviceById("s92")		
	}

	Void testThreadedServicesCanBeInjectedIntoCtor() {
		reg := RegistryBuilder().addModule(T_MyModule100#).build.startup
		t2 := reg.serviceById("s93")
	}
}

internal class T_MyModule83 {
	static Void defineServices(ServiceDefinitions defs) {
		defs.add(T_MyService50#).withId("t50").withScope(ServiceScope.perThread).withProxy
		defs.add(T_MyService50#).withId("t50-thread").withScope(ServiceScope.perThread).withProxy
		defs.add(T_MyService50#).withId("t50-app").withScope(ServiceScope.perApplication)
	}
}

internal class T_MyModule85 {
	static Void defineServices(ServiceDefinitions defs) {
		defs.add(T_MyService70#).withId("t70")
		defs.add(T_MyService85#).withId("t85").withScope(ServiceScope.perThread).withProxy
	}
	
	@Contribute
	static Void contributeT70(Configuration config) {
		config.addPlaceholder("routes")		
		config.set("key69", 69).before("routes")
	}
}

internal class T_MyService70 {
	new make(Int[] config) { }
}

@NoDoc
const mixin T_MyService85 {
	abstract Str judge()
}
@NoDoc
const class T_MyService85Impl : T_MyService85 {
	override Str judge() { "Dredd" }
}

internal class T_MyModule98 {
	static Void defineServices(ServiceDefinitions defs) {
		defs.add(T_MyService89#)		
		defs.add(T_MyService89#).withId("PillowRoutes")
	}
}
internal const class T_MyService89 { }

internal class T_MyModule100 {
	static Void defineServices(ServiceDefinitions defs) {
		defs.add(T_MyService91#).withScope(ServiceScope.perThread)
		defs.add(T_MyService92#).withId("s92")
		defs.add(T_MyService93#).withId("s93")
	}	
}
internal class T_MyService91 { }	// threaded
internal const class T_MyService92 {
	new make(Registry reg, |This|in) { 
		in(this) 
		reg.dependencyByType(T_MyService91#)
	}
}
internal const class T_MyService93 {
	new make(T_MyService91 s91, |This|in) { } 	
}
