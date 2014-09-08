
internal class TestContribDefs : IocTest {
	
	Void testContributionMethodMustBeStatic() {
		verifyIocErrMsg(IocMessages.contributionMethodMustBeStatic(T_MyModule23#contributeWot)) {
			RegistryBuilder().addModule(T_MyModule23#).build.startup
		}  
	}

	Void testContributionMethodMustTakeConfig() {
		verifyIocErrMsg(IocMessages.contributionMethodMustTakeConfig(T_MyModule24#contributeWot)) {
			RegistryBuilder().addModule(T_MyModule24#).build.startup
		}  
	}

	Void testContribDoesNotDefineBothServiceIdAndServiceType() {
		verifyIocErrMsg(IocMessages.contribitionHasBothIdAndType(T_MyModule25#contributeWot)) {
			RegistryBuilder().addModule(T_MyModule25#).build.startup
		}  
	}

	Void testContribDoesNotDefineServiceId() {
		verifyIocErrMsg(IocMessages.contributionMethodDoesNotDefineServiceId(T_MyModule26#cont)) {
			RegistryBuilder().addModule(T_MyModule26#).build.startup
		}  
	}

	Void testErrWhenServiceIdNoExist() {
		verifyIocErrMsg(IocMessages.contributionServiceNotFound(T_MyModule27#cont, "wotever")) {
			RegistryBuilder().addModule(T_MyModule27#).build.startup
		}  
	}

	Void testErrWhenServiceTypeNoExist() {
		verifyIocErrMsg(IocMessages.contributionServiceNotFound(T_MyModule28#cont, "sys::Int")) {
			RegistryBuilder().addModule(T_MyModule28#).build.startup
		}  
	}

	Void testNoErrWhenContibIsOptional() {
		RegistryBuilder().addModule(T_MyModule29#).build.startup
	}
	
	Void testWhenNoConfigDefined() {
		reg := RegistryBuilder().addModule(T_MyModule52#).build.startup
		reg.dependencyByType(T_MyService31#)
		reg.serviceById(T_MyService31#.qname)
	}

	Void testErrWhenConfigMethodsButNotConfigType() {
		verifyIocErrMsg(IocMessages.contributionMethodsNotWanted("s76", [T_MyModule106#contributeWot])) {
			RegistryBuilder().addModule(T_MyModule106#).build.startup
		}
	}
}

internal class T_MyModule23 {
	@Contribute
	Void contributeWot(Configuration config) { }
}

internal class T_MyModule24 {
	@Contribute
	static Void contributeWot(Obj config) { }
}

internal class T_MyModule25 {
	@Contribute { serviceId="wotever"; serviceType=T_MyModule25# }
	static Void contributeWot(Configuration config) { }
}

internal class T_MyModule26 {
	@Contribute
	static Void cont(Configuration config) { }
}

internal class T_MyModule27 {
	@Contribute{serviceId="wotever"}
	static Void cont(Configuration config) { }
}

internal class T_MyModule28 {
	@Contribute{serviceType=Int#}
	static Void cont(Configuration config) { }
}

internal class T_MyModule29 {
	@Contribute{serviceType=Int#; optional=true}
	static Void cont(Configuration config) { }
}

internal class T_MyModule52 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService31#)
	}
}
@NoDoc mixin T_MyService31 { }
@NoDoc class T_MyService31Impl : T_MyService31 {
	new make(DependencyProvider[] config) { }
}

internal class T_MyModule106 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService76#).withId("s76")
	}
	@Contribute { serviceId="s76"}
	static Void contributeWot(Configuration config) { }
}

@NoDoc class T_MyService76 {
	new make() { }

}