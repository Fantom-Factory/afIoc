
internal class TestRegistryBuilder : IocTest {

	Void testRegistryOptionValues() {
		verifyErrMsg(IocMessages.invalidRegistryValue("disableProxies", Int#, Bool#)) { 
			RegistryBuilder().build(["disableProxies":true, "disableProxies":69])
		}
	}
	
	Void testDisabeProxy() {
		reg := (RegistryImpl) RegistryBuilder().addModule(T_MyModule76#).build(["DISableProxIES":true]).startup
		
		stats := (ServiceStats) reg.serviceById(ServiceIds.serviceStats)
		verifyEq(stats.stats["s50"].lifecycle, ServiceLifecycle.DEFINED)
		
		s50 := reg.serviceById("s50")
		verifyEq(stats.stats["s50"].lifecycle, ServiceLifecycle.CREATED)		

		s50->dude
		verifyEq(stats.stats["s50"].lifecycle, ServiceLifecycle.CREATED)		
	}
}
