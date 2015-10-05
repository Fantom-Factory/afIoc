using concurrent

internal class TestThreadedAccess : IocTest {
	
	Void testAppVsThread() {
		root := threadScope { addModule(T_MyModule16#) }.registry.rootScope
		
		app1 := root.serviceById("app")
		the1 := root.serviceById("the")

		Actor(ActorPool()) |->| {
			root.createChildScope("thread") {
				app2 := serviceById("app")
				assertSame(app1, app2)
				
				the2 := serviceById("the")
				assertNotSame(the1, the2)
			}
		}.send(null).get

		Actor(ActorPool()) |->| {
			root.createChildScope("thread") {
				app2 := serviceById("app")
				assertSame(app1, app2)
				
				the2 := serviceById("the")
				assertNotSame(the1, the2)
			}
		}.send(null).get
	}

	Void testThreadInApp() {
		root := threadScope { addModule(T_MyModule17#) }.registry.rootScope
		
		// can find a 'thread' service in 'root'
		verifyErrMsg(ServiceNotFoundErr#, ErrMsgs.scope_couldNotFindServiceById("s12", "builtIn root".split)) {
			s12 := root.serviceById("s12")	// perThread
		}
	
		// can find a 'thread' service into a 'root' service
		verifyErrMsg(ServiceNotFoundErr#, ErrMsgs.scope_couldNotFindServiceByType(T_MyService58#, "builtIn root".split)) {
			s12 := root.serviceById("s13")	// perThread
		}
	}

	Void testErrThrownWhenConstFieldNotSet() {
		reg := threadScope { addModule(T_MyModule19#) }
		// we're now using Fantom's default message
		verifyIocErrMsg("Cannot set const field afIoc::T_MyService14.s12") {
			reg.serviceById("s14")
		}
	}

	Void testThreadedServicesAreDestroyedOnThreadCleansUp() {
		root := threadScope { addModule(T_MyModule17#) }.registry.rootScope
		s02a := null

		root.createChildScope("thread") {
			verifyEq(root.registry.serviceDefs["s12"].noOfInstancesBuilt, 0)
			s02a = serviceById("s12")
			verifyEq(root.registry.serviceDefs["s12"].noOfInstancesBuilt, 1)
		}
		
		root.createChildScope("thread") {
			verifyEq(root.registry.serviceDefs["s12"].noOfInstancesBuilt, 1)
			s02b := serviceById("s12")
			verifyEq(root.registry.serviceDefs["s12"].noOfInstancesBuilt, 2)
			
			assertNotSame(s02a, s02b)
		}
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

internal const class T_MyModule16 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService58#).withId("app").withScopes(["root"])
		defs.addService(T_MyService58#).withId("the").withScopes(["root", "thread"])
	}
}

internal const class T_MyModule17 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService58#).withId("s12").withScopes(["thread"])
		defs.addService(T_MyService13#).withId("s13").withScopes(["root"])
	}
}

internal const class T_MyModule18 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService58#).withId("s12").withScopes(["root"])
		defs.addService(T_MyService13#).withId("s13").withScopes(["root", "thread"])
	}
}

internal const class T_MyModule19 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService58#).withId("s12")
		defs.addService(T_MyService14#).withId("s14")
	}
}

internal const class T_MyModule90 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService02#).withId("s02").withScopes(["thread"])
	}
}

internal const class T_MyService58 {
	const Str kick	:= "DREDD"
}

internal const class T_MyService13 {
	@Inject
	const T_MyService58 s12
	new make(|This|in) { in(this) }
}

internal class T_MyService14 {
	@Inject
	const T_MyService58? s12
}


internal const class T_MyModule77 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService61#).withId("s61").withScopes(["thread"])
		defs.addService(T_MyService62#).withId("s62").withScopes(["root"])
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
