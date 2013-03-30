
class TestModule : Test {
	
	Void testUnrecognisedModuleMethods() {
		verifyErr(IocErr#) {   			
			reg := RegistryBuilder().addModule(T_MyModule2#).build
		}
	}
	
	Void testBindMethodMustBeStatic() {
		
		// binder method must be static
		verifyErr(IocErr#) {   			
			reg := RegistryBuilder().addModule(T_MyModule8#).build
		}		

		// binder method must only have the one param
		verifyErr(IocErr#) {   			
			reg := RegistryBuilder().addModule(T_MyModule9#).build
		}		

		// binder method param must be type ServiceBinder
		verifyErr(IocErr#) {   			
			reg := RegistryBuilder().addModule(T_MyModule10#).build
		}		
	}
	
	Void testSubModule() {
		reg := RegistryBuilder().addModule(T_MyModule12#).build
		reg.dependencyByType(T_MyService2#)
	}
	
	Void testBindImplFindsImpl() {
		reg :=  RegistryBuilder().addModule(T_MyModule13#).build.startup
		reg.serviceById("yo")
	}
	
	Void testBindImplFitsMixin() {
		verifyErr(IocErr#) {   			
			RegistryBuilder().addModule(T_MyModule14#).build
		}
	}
	
	Void testBindImplFitsMixinErrIfNot() {
		verifyErr(IocErr#) {   			
			RegistryBuilder().addModule(T_MyModule15#).build
		}
	}
}

internal class T_MyModule2 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService1#)		
	}
	
	static Void doDaa() {
		// nuffin
	}
}

internal class T_MyModule8 {
	Void bind(ServiceBinder binder) { }
}

internal class T_MyModule9 {
	static Void bind(ServiceBinder binder, Obj wotever) { }
}

internal class T_MyModule10 {
	static Void bind(Obj wotever) { }
}

@SubModule{modules=[T_MyModule1#]}
internal class T_MyModule12 {
}

internal class T_MyModule13 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService10#).withId("yo")
	}
}

internal class T_MyModule14 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService11#).withId("yo")
	}
}

internal class T_MyModule15 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService1#, T_MyService2#)
	}
}

internal mixin T_MyService10 { }
internal class T_MyService10Impl : T_MyService10 { }

internal mixin T_MyService11 { }
internal mixin T_MyService11Impl : T_MyService11 { }

