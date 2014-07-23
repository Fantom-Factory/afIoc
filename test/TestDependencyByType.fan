
internal class TestDependencyByType : IocTest {
	
	Void testStaticInjectionGivesErr() {
		verifyIocErrMsg(IocMessages.injectionUtils_fieldIsStatic(T_MyService97#registry)) {			
			RegistryBuilder().build.autobuild(T_MyService97#)
		}
	}
	
	Void testCheckedFalse() {	
		reg := RegistryBuilder().addModule(T_MyModule99#).build.startup
		str := reg.dependencyByType(Str#, false)
		verifyNull(str)
	}

	Void testInheritenceSearch() {
		reg := RegistryBuilder().addModule(T_MyModule99#).build.startup
		
		mix := reg.dependencyByType(T_MyService91_Meta#)
		verifyEq(mix->judge, "anderson")

		mix = reg.dependencyByType(T_MyService91_Options#)
		verifyEq(mix->judge, "anderson")
	}
}

internal const mixin T_MyService91_Meta { abstract Str judge() }
internal const mixin T_MyService91_Options  : T_MyService91_Meta	{ override Str judge(){"dredd"} }
internal const class T_MyService91_MetaImpl : T_MyService91_Options	{ override Str judge(){"anderson"} }

internal class T_MyModule99 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService91_Options#, T_MyService91_MetaImpl#).withoutProxy
	}
}

internal class T_MyService97 {
	@Inject static const Registry? registry
}