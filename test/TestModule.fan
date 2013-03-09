
class TestModule : Test {
	
	Void testUnrecognisedModuleMethods() {
		verifyErr(IocErr#) {   			
			reg := RegistryBuilder().addType(T_MyModule2#).build
		}
	}
	
}

class T_MyModule2 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService1#)		
	}
	
	static Void doDaa() {
		// nuffin
	}
}