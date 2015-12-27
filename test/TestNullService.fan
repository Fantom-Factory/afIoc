
@Js
internal class TestNullService : IocTest {

	Void testNullServiceDef() {
		scope := rootScope { 
			addService(T_MyService75#).withId("s75").withBuilder { null }
		}

		s75 := scope.serviceById("s75")
		verifyNull(s75)

		s75 = scope.serviceByType(T_MyService75#)
		verifyNull(s75)
	}
}

