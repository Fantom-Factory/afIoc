
internal class TestRegistryBuilder : IocTest {

	Void testBannerText() {
		RegistryBuilder().build(["bannerText":"align right"]).startup
		RegistryBuilder().build(["bannerText":"I'm completely operational and all my circuits are  functioning perfectly. - HAL 9000"]).startup
	}

	Void testRegistryMeta() {
		reg  := RegistryBuilder().build(["hereMeNow":true, "meNull":null])
		opts := (RegistryMeta) reg.dependencyByType(RegistryMeta#)
		verify(opts.options["hereMeNow"])
	}

	Void testRegistryOptionsCanBeNull() {
		reg  := RegistryBuilder().build(["meNull":null])
		opts := (RegistryMeta) reg.dependencyByType(RegistryMeta#)
		verify(opts.options.containsKey("meNull"))
		verifyNull(opts.options["meNull"])
	}

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
	
	Void testSuppressLoggingIsAlwaysAddedToOpts() {
		// build used to Err if 'SuppressLogging' was not explicitly defined 
		reg := RegistryBuilder(["wotever":true]).addModule(T_MyModule76#).build
		
		// check the reg build ok
		verifyNotNull(reg.serviceById(ServiceIds.serviceStats))
	}

	Void testRegistryOptionsBecomeCaseInsensitve() {
		reg := RegistryBuilder().build(Str:Obj?[:] { it.caseInsensitive=false }.add("wot", "ever"))
		
		verifyEq(reg.serviceById(ServiceIds.registryMeta)->get("WOT"), "ever")
	}
}
