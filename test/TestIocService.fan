using concurrent

internal class TestIocService : IocTest {

	Void testLocks() {
		ioc := IocService()
		
		try {
			verifyIocErrMsg(IocMessages.serviceNotStarted) {
				ioc.serviceById("")
			}
			verifyIocErrMsg(IocMessages.serviceNotStarted) {
				ioc.dependencyByType(Obj#)
			}
			verifyIocErrMsg(IocMessages.serviceNotStarted) {
				ioc.autobuild(Obj#)
			}
			verifyIocErrMsg(IocMessages.serviceNotStarted) {
				ioc.injectIntoFields(this)
			}
		
			ioc.start
	
			// sys::Service doesn't let us start the service twice
//			verifyIocErrMsg(IocMessages.serviceStarted) {
//				ioc.start
//			}
			verifyIocErrMsg(IocMessages.serviceStarted) {
				ioc.addModules([,])
			}
			verifyIocErrMsg(IocMessages.serviceStarted) {
				ioc.addModulesFromPod("afIoc")
			}
			verifyIocErrMsg(IocMessages.serviceStarted) {
				ioc.addModulesFromIndexProps
			}
		} finally {
			ioc.uninstall
		}
	}
	
	Void testServicesAreIsolatedToIocInstances() {
		IocService? ioc1
		IocService? ioc2
		IocService? ioc3
		try {
			ioc1 = IocService([T_MyModule16#]).start
			ioc2 = IocService([T_MyModule16#]).start
			ioc3 = IocService().start
			
			app1 := ioc1.serviceById("app")
			the1 := ioc1.serviceById("the")

			app2 := ioc2.serviceById("app")
			the2 := ioc2.serviceById("the")
			
			// neither app not thread scoped services should be the same
			assertNotSame(app1, app2)
			assertNotSame(the1, the2)
			
			verifyErr(ServiceNotFoundErr#) { ioc3.serviceById("app") }
			verifyErr(ServiceNotFoundErr#) { ioc3.serviceById("the") }
			
		} finally {
			ioc1?.uninstall
			ioc2?.uninstall
			ioc3?.uninstall
		}
	}
	
	Void testThreadedAccessToSameService() {
		reggy := IocService([T_MyModule16#]).start
		try {
	
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
			
		} finally {
			reggy.uninstall
		}
	}

	Void testIocServiceMayBeUsedDuringStartup() {
		iocs := IocService([T_MyModule54#]).install
		try {
			iocs.onStart
		} finally {
			iocs.uninstall
		}
	}
	
	** see http://fantom.org/sidewalk/topic/2133
	Void testStartErrsAreRethrown() {
		iocs := IocService([T_MyModule101#]).start
		try {
			verifyErrMsg(Err#, "Boobies!") { 
				iocs.registry.serviceById("wotever")
			}
			verifyFalse(iocs.isRunning)
		} finally {
			iocs.uninstall
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
}

internal class T_MyModule54 {
	static Void defineServices(ServiceDefinitions defs) {
		defs.add(T_MyService02#).withId("s2")
	}
	@Contribute
	static Void contributeRegistryStartup(Configuration config) {
		config.add() |->| {
			(Service.find(IocService#) as IocService).serviceById("s2")
		}
	}
}

internal class T_MyModule101 {
	@Contribute
	static Void contributeRegistryStartup(Configuration config) {
		config.add() |->| { throw Err("Boobies!") }
	}
}

