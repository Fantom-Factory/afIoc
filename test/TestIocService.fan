using concurrent

class TestIocService : Test {

	Void testThreads() {
		reggy := IocService([T_MyModule16#]).start
		
		Utils.setLoglevelDebug
		app1 := reggy.serviceById("app")
		the1 := reggy.serviceById("the")

		Actor(ActorPool()) |->| {
			try {
			reg := (Service.find(IocService#) as IocService)
			app2 := reg.serviceById("app")
			assertSame(app1, app2)
			
			the2 := reg.serviceById("the")
			assertNotSame(the1, the2)
				
			} catch (Err r) {
				r.trace
			}
		}.send(null).get

		Actor(ActorPool()) |->| {
			reg := (Service.find(IocService#) as IocService)
			app2 := reg.serviceById("app")
			assertSame(app1, app2)
			
			the2 := reg.serviceById("the")
			assertNotSame(the1, the2)
		}.send(null).get
	}

	
	static Void assertSame(Obj? o1, Obj? o2) {
		if (o1 !== o2)
			throw Err("Are NOT the same - $o1 : $o2")
	}

	static Void assertNotSame(Obj? o1, Obj? o2) {
		if (o1 === o2)
			throw Err("ARE the same - $o1 : $o2")
	}
}

