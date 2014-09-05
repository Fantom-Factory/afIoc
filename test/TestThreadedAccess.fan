using concurrent

internal class TestThreadedAccess : IocTest {
	
	Void testAppVsThread() {
		Registry reg := RegistryBuilder().addModule(T_MyModule16#).build.startup
		
		app1 := reg.serviceById("app")
		the1 := reg.serviceById("the")

		Actor(ActorPool()) |->| {
			app2 := reg.serviceById("app")
			assertSame(app1, app2)
			
			the2 := reg.serviceById("the")
			assertNotSame(the1, the2)
		}.send(null).get

		Actor(ActorPool()) |->| {
			app2 := reg.serviceById("app")
			assertSame(app1, app2)
			
			the2 := reg.serviceById("the")
			assertNotSame(the1, the2)
		}.send(null).get
	}

	Void testThreadInApp() {
		Registry reg := RegistryBuilder().addModule(T_MyModule17#).build.startup

		// can not inject a perThread service into a perApp service
		verifyIocErrMsg(IocMessages.threadScopeInAppScope("s13", "s12")) {
			s12 := reg.serviceById("s12")	// perThread
			s13 := reg.serviceById("s13")	// perApp
		}

//		Actor(ActorPool()) |->| {
//			s12i := reg.serviceById("s12")
//			assertNotSame(s12, s12i)
//
//			s13i := reg.serviceById("s13")
//			assertSame(s13, s13i)
//
//			assertNotSame(s13->s12, s13i->s12)
//		}.send(null).get
	}
	
	Void testProxyThreadInApp() {
		Registry reg := RegistryBuilder().addModule(T_MyModule77#).build.startup

		// CAN inject a PROXY perThread service into a perApp service
		s61 := reg.serviceById("s61")	// perThread
		s62 := reg.serviceById("s62")	// perApp
		s62->s61->kickIn("all-change")
		kick1 := s62->s61->kickOut
		
		Actor(ActorPool()) |->| {
			s61i := reg.serviceById("s61")
			assertNotSame(s61, s61i)

			s62i := reg.serviceById("s62")
			assertSame(s62, s62i)
			
			// check this...
			
			// ...the same service
			assertSame(s62->s61, s62i->s61)
			
			// ...gives different results!
			kick2 := s62i->s61->kickOut
			assertNotEq(kick1, kick2)

		}.send(null).get
	}

	Void testAppInThread() {
		Registry reg := RegistryBuilder().addModule(T_MyModule18#).build.startup

		s12 := reg.serviceById("s12")	// perApp
		s13 := reg.serviceById("s13")	// perThread

		Actor(ActorPool()) |->| {
			s12i := reg.serviceById("s12")
			assertSame(s12, s12i)

			s13i := reg.serviceById("s13")
			assertNotSame(s13, s13i)

			assertSame(s13->s12, s13i->s12)
			
		}.send(null).get
	}

	Void testErrThrownWhenConstFieldNotSet() {
		Registry reg := RegistryBuilder().addModule(T_MyModule19#).build.startup
		verifyIocErrMsg(IocMessages.cannotSetConstFields(T_MyService14#s12)) {
			reg.serviceById("s14")
		}
	}

	Void testThreadedServicesAreDestroyedOnThreadCleansUp() {
		reg := (Registry) RegistryBuilder().addModule(T_MyModule90#).build.startup
		tlm := (ThreadLocalManager) reg.serviceById(ThreadLocalManager#.qname)
		
		verifyEq(reg.serviceDefinitions["s02"].lifecycle, ServiceLifecycle.defined)
		s02a := reg.serviceById("s02")
		verifyEq(reg.serviceDefinitions["s02"].lifecycle, ServiceLifecycle.created)
		
		tlm.cleanUpThread
		
		verifyEq(reg.serviceDefinitions["s02"].lifecycle, ServiceLifecycle.defined)
		s02b := reg.serviceById("s02")
		verifyEq(reg.serviceDefinitions["s02"].lifecycle, ServiceLifecycle.created)
		
		assertNotSame(s02a, s02b)
	}

	static Void assertSame(Obj? o1, Obj? o2) {
		if (o1 !== o2)
			throw Err("Are NOT the same - $o1 : $o2")
	}

	static Void assertNotSame(Obj? o1, Obj? o2) {
		if (o1 === o2)
			throw Err("ARE the same - $o1 : $o2")
	}

	static Void assertNotEq(Obj? o1, Obj? o2) {
		if (o1 == o2)
			throw Err("ARE equal - $o1 : $o2")
	}
}

internal class T_MyModule16 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService12#).withId("app").withScope(ServiceScope.perApplication)
		binder.bind(T_MyService12#).withId("the").withScope(ServiceScope.perThread)
	}
}

internal class T_MyModule17 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService12#).withId("s12").withScope(ServiceScope.perThread)
		binder.bind(T_MyService13#).withId("s13").withScope(ServiceScope.perApplication)
	}
}

internal class T_MyModule18 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService12#).withId("s12").withScope(ServiceScope.perApplication)
		binder.bind(T_MyService13#).withId("s13").withScope(ServiceScope.perThread)
	}
}

internal class T_MyModule19 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService12#).withId("s12")
		binder.bind(T_MyService14#).withId("s14")
	}
}

internal class T_MyModule90 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService02#).withId("s02").withScope(ServiceScope.perThread)
	}
}

internal const class T_MyService12 {
	const Str kick	:= "DREDD"
}

internal const class T_MyService13 {
	@Inject
	const T_MyService12 s12
	new make(|This|in) { in(this) }
}

internal class T_MyService14 {
	@Inject
	const T_MyService12? s12
}


internal class T_MyModule77 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService61#).withId("s61").withScope(ServiceScope.perThread)
		binder.bind(T_MyService62#).withId("s62").withScope(ServiceScope.perApplication)
	}
}
@NoDoc const mixin T_MyService61 {
	abstract Void kickIn(Str k)
	abstract Str kickOut()
}
@NoDoc internal const class T_MyService61Impl : T_MyService61 {
	const AtomicRef kick := AtomicRef("dredd") 
	override Void kickIn(Str k) { kick.val = k}
	override Str kickOut() { kick.val } 
}
@NoDoc internal const class T_MyService62 {
	const T_MyService61 s61
	new make(T_MyService61 s61) { this.s61 = s61 }
}
