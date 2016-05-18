
@Js
internal class TestPostInjection : IocTest {

	Void testPrivateFieldsAreNotHidden() {
		reg := threadScope { addService(T_MyService83#) }

		// set via service creation
		srv := reg.serviceByType(T_MyService83#) as T_MyService83
		verifyEq(srv.judge, "Dredd")

		// set via build()
		srv = reg.build(T_MyService83#) as T_MyService83
		verifyEq(srv.judge, "Dredd")

		// set via inject()
		srv = reg.inject(T_MyService83())
		verifyEq(srv.judge, "Dredd")
	}
}

@Js
class T_MyService83 {
	
	Str? judge
	
	@PostInjection
	Void doIt() {
		judge = "Dredd"
	}
}