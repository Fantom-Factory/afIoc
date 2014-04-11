
internal class TestDependencyByType : IocTest {
	
	Void testStaticInjectionGivesErr() {
		verifyErrMsg(IocMessages.injectionUtils_fieldIsStatic(T_MyService97#registry)) {			
			RegistryBuilder().build.autobuild(T_MyService97#)
		}
	}
	
	Void testCheckedFalse() {	
		reg := RegistryBuilder().addModule(T_MyModule99#).build.startup
		str := reg.dependencyByType(Str#, false)
		verifyNull(str)
	}

	// TODO: Inheritence search for services - seems a lots of work, so need a compelling use case.
	// 'cos someone may want an Obj# injected, so we need to return ALL fitting services and bitch if there's more than one
//	Void testInheritenceSearch() {	
//		reg := RegistryBuilder().addModule(T_MyModule99#).build.startup
//		
//		mix := reg.dependencyByType(T_MyService91_2#)
//		verifyEq(mix->judge, "anderson")
//
//		mix = reg.dependencyByType(T_MyService91_1#)
//		verifyEq(mix->judge, "anderson")
//	}
}

internal const mixin T_MyService91_1 { abstract Str judge() }
internal const mixin T_MyService91_2 : T_MyService91_1 	 { override Str judge(){"dredd"} }
internal const class T_MyService91Impl : T_MyService91_2 { override Str judge(){"anderson"} }

internal class T_MyModule99 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService91_2#, T_MyService91Impl#).withoutProxy
	}
}

internal class T_MyService97 {
	@Inject static const Registry? registry
}