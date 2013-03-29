
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
