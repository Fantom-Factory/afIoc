
class TestContribDefs : IocTest {
	
	Void testContributionMethodMustBeStatic() {
		verifyErrMsg(IocMessages.contributionMethodMustBeStatic(T_MyModule23#contributeWot)) {
			RegistryBuilder().addModule(T_MyModule23#).build.startup
		}  
	}

	Void testContributionMethodMustTakeConfig() {
		verifyErrMsg(IocMessages.contributionMethodMustTakeConfig(T_MyModule24#contributeWot)) {
			RegistryBuilder().addModule(T_MyModule24#).build.startup
		}  
	}

	Void testContribDoesNotDefineBothServiceIdAndServiceType() {
		verifyErrMsg(IocMessages.contribitionHasBothIdAndType(T_MyModule25#contributeWot)) {
			RegistryBuilder().addModule(T_MyModule25#).build.startup
		}  
	}

	Void testContribDoesNotDefineServiceId() {
		verifyErrMsg(IocMessages.contributionMethodDoesNotDefineServiceId(T_MyModule26#cont)) {
			RegistryBuilder().addModule(T_MyModule26#).build.startup
		}  
	}

	Void testErrWhenServiceIdNoExist() {
		verifyErrMsg(IocMessages.contributionMethodServiceIdDoesNotExist(T_MyModule27#cont, "wotever")) {
			RegistryBuilder().addModule(T_MyModule27#).build.startup
		}  
	}

	Void testErrWhenServiceTypeNoExist() {
		verifyErrMsg(IocMessages.contributionMethodServiceTypeDoesNotExist(T_MyModule28#cont, Int#)) {
			RegistryBuilder().addModule(T_MyModule28#).build.startup
		}  
	}

	Void testNoErrWhenContibIsOptional() {
		RegistryBuilder().addModule(T_MyModule29#).build.startup
	}
	
	Void testWhenNoConfigDefined() {
		reg := RegistryBuilder().addModule(T_MyModule52#).build.startup
		reg.dependencyByType(PublicTestTypes.type("T_MyService31"))
		reg.serviceById("T_MyService31")
	}
}

internal class T_MyModule23 {
	@Contribute
	Void contributeWot(OrderedConfig config) { }
}

internal class T_MyModule24 {
	@Contribute
	static Void contributeWot(Obj config) { }
}

internal class T_MyModule25 {
	@Contribute { serviceId="wotever"; serviceType=T_MyModule25# }
	static Void contributeWot(OrderedConfig config) { }
}

internal class T_MyModule26 {
	@Contribute
	static Void cont(OrderedConfig config) { }
}

internal class T_MyModule27 {
	@Contribute{serviceId="wotever"}
	static Void cont(OrderedConfig config) { }
}

internal class T_MyModule28 {
	@Contribute{serviceType=Int#}
	static Void cont(OrderedConfig config) { }
}

internal class T_MyModule29 {
	@Contribute{serviceType=Int#; optional=true}
	static Void cont(OrderedConfig config) { }
}

internal class T_MyModule52 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(PublicTestTypes.type("T_MyService31"))
	}
}

