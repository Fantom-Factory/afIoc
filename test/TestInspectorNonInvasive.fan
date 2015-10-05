
internal class TestInspectorNonInvasive : IocTest {
	
	Void testServices() {
		thread := threadScope { addModule(T_MyModule08#) }
		
		verifyEq(T_MyService02#, thread.serviceById("s02").typeof)
		verifyEq(T_MyService02#, thread.serviceByType(T_MyService02#).typeof)
	}
}

internal const class T_MyModule08 {
	
	Str:Obj defineModule() {
		[
			"services"	: [
				[
					"id"	: "s02",
					"type"	: T_MyService02#,
					"scopes": ["thread"]
				]
			]
		]
	}
}