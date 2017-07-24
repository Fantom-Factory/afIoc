
internal class TestGlobalRegistry : IocTest {
	
	override Void teardown() {
		super.teardown
		Registry.clearGlobal
	}
	
	Void testGlobal() {
		reg := rootScope { 
			addService(T_MyService88#)
		}.registry.setAsGlobal
		
		service := T_MyService88()
		
		verifyNotNull(service.scope)
	}
	
	Void testErrs() {
		verifyErrMsg(Err#, ErrMsgs.registry_globalNotSet) |->| {
			Registry.getGlobal
		}
		
		RegistryBuilder().build.setAsGlobal
		verifyErrMsg(Err#, ErrMsgs.registry_globalAlreadySet) |->| {
			RegistryBuilder().build.setAsGlobal
		}
	}
}

const class T_MyService88 {
	@Inject const Scope scope
	
	private new makeViaItBlock(|This| f) { f(this) }

	static new make() {
		Registry.getGlobal.activeScope.build(T_MyService88#)
	}
}
