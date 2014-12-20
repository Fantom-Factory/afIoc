
internal class TestRegistryBuilder : IocTest {

	Void testBannerText() {
		RegistryBuilder().set("afIoc.bannerText","align right").build.startup
		RegistryBuilder().set("afIoc.bannerText","I'm completely operational and all my circuits are  functioning perfectly. - HAL 9000").build.startup
	}

	Void testRegistryMeta() {
		reg := RegistryBuilder().set("hereMeNow", true).build
		opts := (RegistryMeta) reg.dependencyByType(RegistryMeta#)
		verify(opts.options["hereMeNow"])
	}

	Void testRegistryOptionsCanBeNull() {
		reg := RegistryBuilder().set("meNull", null).build
		opts := (RegistryMeta) reg.dependencyByType(RegistryMeta#)
		verify(opts.options.containsKey("meNull"))
		verifyNull(opts.options["meNull"])
	}

	Void testRegistryOptionValues() {
		bob := RegistryBuilder()
		bob.options["afIoc.bannerText"] = true
		verifyIocErrMsg(IocMessages.invalidRegistryValue("afIoc.bannerText", Bool#, Str#)) { 
			bob.build
		}
	}
}
