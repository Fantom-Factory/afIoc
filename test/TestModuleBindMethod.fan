
internal class TestModuleBindMethod : IocTest {
	
	Void testBindMethodMustBeStatic() {
		
		// binder method must be static
		verifyIocErrMsg(IocMessages.moduleMethodMustBeStatic(T_MyModule08#defineServices)) {
			RegistryBuilder().addModule(T_MyModule08#).build
		}		

		// binder method must only have the one param
		verifyIocErrMsg(IocMessages.moduleMethodWithWrongDefineParams(T_MyModule09#defineServices)) {
			RegistryBuilder().addModule(T_MyModule09#).build
		}		

		// binder method param must be type ServiceBinder
		verifyIocErrMsg(IocMessages.moduleMethodWithWrongDefineParams(T_MyModule10#defineServices)) {
			RegistryBuilder().addModule(T_MyModule10#).build
		}		
	}

	Void testBindImplFindsImpl() {
		reg :=  RegistryBuilder().addModule(T_MyModule13#).build.startup
		reg.serviceById("yo")
	}

	Void testBindImplFitsMixin() {
		verifyIocErrMsg(IocMessages.bindImplNotClass(T_MyService11Impl#)) {   			
			RegistryBuilder().addModule(T_MyModule14#).build
		}
	}

	Void testBindImplFitsMixinErrIfNot() {
		verifyIocErrMsg(IocMessages.bindImplDoesNotFit(T_MyService01#, T_MyService02#)) {   			
			RegistryBuilder().addModule(T_MyModule15#).build
		}
	}
}

internal class T_MyModule08 {
	Void defineServices(ServiceDefinitions defs) { }
}

internal class T_MyModule09 {
	static Void defineServices(ServiceDefinitions defs, Obj wotever) { }
}

internal class T_MyModule10 {
	static Void defineServices(Float wotever) { }
}

internal class T_MyModule13 {
	static Void defineServices(ServiceDefinitions defs) {
		defs.add(T_MyService03#).withId("yo")
	}
}
@NoDoc mixin T_MyService03 { }
@NoDoc class T_MyService03Impl : T_MyService03 { }
		
internal class T_MyModule14 {
	static Void defineServices(ServiceDefinitions defs) {
		defs.add(T_MyService11#).withId("yo")
	}
}

internal class T_MyModule15 {
	static Void defineServices(ServiceDefinitions defs) {
		defs.add(T_MyService01#, T_MyService02#)
	}
}

internal mixin T_MyService11 { }
internal mixin T_MyService11Impl : T_MyService11 { }

