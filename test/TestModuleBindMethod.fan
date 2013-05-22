
class TestModuleBindMethod : IocTest {
	
	Void testBindMethodMustBeStatic() {
		
		// binder method must be static
		verifyErrMsg(IocMessages.bindMethodMustBeStatic(T_MyModule8#bind)) {
			RegistryBuilder().addModule(T_MyModule8#).build
		}		

		// binder method must only have the one param
		verifyErrMsg(IocMessages.bindMethodWrongParams(T_MyModule9#bind)) {
			RegistryBuilder().addModule(T_MyModule9#).build
		}		

		// binder method param must be type ServiceBinder
		verifyErrMsg(IocMessages.bindMethodWrongParams(T_MyModule10#bind)) {
			RegistryBuilder().addModule(T_MyModule10#).build
		}		
	}

	Void testBindImplFindsImpl() {
		reg :=  RegistryBuilder().addModule(T_MyModule13#).build.startup
		reg.serviceById("yo")
	}

	Void testBindImplFitsMixin() {
		verifyErrMsg(IocMessages.bindImplNotClass(T_MyService11Impl#)) {   			
			RegistryBuilder().addModule(T_MyModule14#).build
		}
	}

	Void testBindImplFitsMixinErrIfNot() {
		verifyErrMsg(IocMessages.bindImplDoesNotFit(T_MyService1#, T_MyService2#)) {   			
			RegistryBuilder().addModule(T_MyModule15#).build
		}
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

internal class T_MyModule13 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(PublicTestTypes.type("T_MyService10")).withId("yo")
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

internal mixin T_MyService11 { }
internal mixin T_MyService11Impl : T_MyService11 { }

