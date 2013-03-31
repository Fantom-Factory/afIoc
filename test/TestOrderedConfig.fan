
class TestOrderedConfig : IocTest {
	
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

	Void testConfig() {
		Utils.setLoglevelDebug
		reg := RegistryBuilder().addModule(T_MyModule24#).build.startup
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
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService19#).withId("s19")
	}
}

internal class T_MyService19 {
	new make(Str[] config) {
		
	}
}