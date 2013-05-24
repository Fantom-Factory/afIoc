
internal class TestModuleSubModule : IocTest {
	
	Void testSubModule() {
		reg := RegistryBuilder().addModule(T_MyModule12#).build
		reg.dependencyByType(T_MyService2#)
	}
	
}


@SubModule{modules=[T_MyModule1#]}
internal class T_MyModule12 { }
