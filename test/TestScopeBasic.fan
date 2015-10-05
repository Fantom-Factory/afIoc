
@Js
internal class TestScopeBasic : IocTest {

	Void testServiceById() {
		reg := threadScope { addModule(T_MyModule01#) }
		s01 := (T_MyService01) reg.serviceById(T_MyService01#.qname.lower)
		verifyEq(s01.service.kick, "ASS!")
		verifySame(s01, reg.serviceById(T_MyService01#.qname.lower))

		oops := reg.serviceById("oops", false)
		verifyNull(oops)
	}

	Void testServiceByType() {
		reg := threadScope { addModule(T_MyModule01#) }
		s01 := (T_MyService01) reg.serviceByType(T_MyService01#)
		verifyEq(s01.service.kick, "ASS!")
		verifySame(s01, reg.serviceByType(T_MyService01#))
		
		oops := reg.serviceByType(Int#, false)
		verifyNull(oops)
	}

	Void testBuild() {
		reg := threadScope { addModule(T_MyModule01#) }
		s01 := (T_MyService01) reg.build(T_MyService01#)
		verifyEq(s01.service.kick, "ASS!")
		verifyNotSame(s01, reg.build(T_MyService01#))
	}
	
	Void testInject() {
		reg := threadScope { addModule(T_MyModule01#) }
		s01 := T_MyService01()
		verifyNull(s01.service)
		reg.inject(s01)
		verifyEq(s01.service.kick, "ASS!")
	}
}

@Js
internal const class T_MyModule01 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService01#)
		defs.addService(T_MyService02#)
	}
}

@Js
internal class T_MyService01 {
	@Inject	T_MyService02? service
}
