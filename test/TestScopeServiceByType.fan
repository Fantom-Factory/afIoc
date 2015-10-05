
@Js
internal class TestScopeServiceByType : IocTest {
	
	Void testCheckedFalse() {	
		s01 := rootScope.serviceByType(Str#, false)
		verifyNull(s01)
	}
}
