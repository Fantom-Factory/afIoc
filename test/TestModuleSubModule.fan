
internal class TestModuleSubModule : IocTest {
	
	Void testSubModule() {
		reg := RegistryBuilder().addModule(T_MyModule12#).build
		reg.dependencyByType(T_MyService02#)
	}
	
}


@SubModule{modules=[T_MyModule01#]}
internal class T_MyModule12 { }
