
@Js
internal class TestFacetBuild : IocTest {
	
	Void testBuilderMethod() {
		reg := threadScope { addModule(T_MyModule04#) }
		myService1 := (T_MyService01) reg.serviceById(T_MyService01#.qname)
		verifyEq(myService1.service.kick, "Penguin")

		myService2 := (T_MyService01) reg.serviceByType(T_MyService01#)
		verifySame(myService1, myService2)
	}

	Void testBuilderMethodWithParams() {
		reg := threadScope { addModule(T_MyModule05#) }
		myService1 := (T_MyService01) reg.serviceById("penguin")
		verifyEq(myService1.service.kick, "Penguin")

		myService2 := (T_MyService01) reg.serviceById("goose")
		verifyEq(myService2.service.kick, "ASS!")

		verifyNotSame(myService1, myService2)
	}
	
	Void testWrongScope1() {
		// autobuild
		verifyIocErrMsg(ErrMsgs.serviceBuilder_scopeIsThreaded(T_MyService01#.qname, "root")) {
			RegistryBuilder().addModule(T_MyModule21#).build
		}
	}

	Void testWrongScope2() {
		// build method
		verifyIocErrMsg(ErrMsgs.serviceBuilder_scopeIsThreaded(T_MyService01#.qname, "root")) {
			RegistryBuilder().addModule(T_MyModule22#).build
		}
	}
	
	Void testBuilderMethodAppearsInStackTrace() {
		// Stack traces not available in JS 
		if (Env.cur.runtime == "js") return
		
		try {
			reg := threadScope { addModule(T_MyModule91#) }
			reg.serviceById("t1")
			fail
		} catch (Err e) {
			verify(e.traceToStr.contains("afIoc::T_MyModule91.buildT1"))
		}
	}

}

@Js
internal const class T_MyModule04 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService02#)
	}
	
	@Build
	static T_MyService01 buildPenguin() {
		ser2 := T_MyService02()
		ser2.kick = "Penguin"
		ser1 := T_MyService01()
		ser1.service = ser2
		return ser1
	}
}

@Js
internal const class T_MyModule05 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService02#)
	}
	
	@Build { serviceId = "penguin" }
	static T_MyService01 buildPenguin() {
		ser2 := T_MyService02()
		ser2.kick = "Penguin"
		ser1 := T_MyService01()
		ser1.service = ser2
		return ser1
	}

	@Build { serviceId = "goose" }
	static T_MyService01 buildGoose(T_MyService02 ser2) {
		ser1 := T_MyService01()
		ser1.service = ser2
		return ser1
	}
}

@Js
internal const class T_MyModule21 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService01#).withScopes(["root"])
	}
}

@Js
internal const class T_MyModule22 {
	@Build { scopes=["root"] }
	static T_MyService01 buildT1() {
		return T_MyService01()
	}
}

@Js
internal const class T_MyModule91 {
	@Build { serviceId = "t1" }
	static T_MyService01 buildT1() {
		throw Err("Bugger!")
	}
}
