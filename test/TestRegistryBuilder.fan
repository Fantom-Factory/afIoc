
internal class TestRegistryBuilder : IocTest {
	
	Void testRegistryOptionKeys() {
		verifyErrMsg(IocMessages.invalidRegistryOptions(["Wotup!?", "Nuffin"], ["disableProxies", "eagerLoadBuiltInServices", "logServiceCreation"])) { 
			RegistryBuilder().build(["disableProxies":true, "Wotup!?":true, "Nuffin":69])
		}
	}

	Void testRegistryOptionValues() {
		verifyErrMsg(IocMessages.invalidRegistryValue("eagerLoadBuiltInServices", Int#, Bool#)) { 
			RegistryBuilder().build(["disableProxies":true, "eagerLoadBuiltInServices":69])
		}
	}
}
