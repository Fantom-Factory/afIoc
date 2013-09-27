
// FUTURE: see http://fantom.org/sidewalk/topic/2186

//internal class TestInjectFacetInheritance : IocTest {
//		
//	Void testInjectIsInherited() {
//		t := (T_Class01) RegistryBuilder().build.autobuild(T_Class01#)
//		verifyNotNull(t.reg)
//		t.reg.shutdown
//	}	
//}
//
//internal mixin T_Mixin01 { 
//	@Inject
//	abstract Registry reg
//}
//
//internal class T_Class01 : T_Mixin01 {
//	override Registry reg
//	new make(|This|in) { in(this) }
//}