
@Js
internal class TestFacetSubModule : IocTest {
	
	Void testSubModule() {
		reg := threadScope { addModule(T_MyModule12#) }
		reg.serviceByType(T_MyService02#)
	}
	
}

@Js
@SubModule{modules=[T_MyModule01#]}
internal const class T_MyModule12 { }
