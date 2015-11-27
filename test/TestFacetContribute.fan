
@Js
internal class TestFacetContribute : IocTest {
	
	Void testContributionMethodMustTakeConfig() {
		verifyIocErrMsg(ErrMsgs.contributions_contributionMethodMustTakeConfig(T_MyModule24#contributeWot)) {
			RegistryBuilder().addModule(T_MyModule24#).build
		}  
	}

	Void testContribDoesNotDefineBothServiceIdAndServiceType() {
		verifyIocErrMsg(ErrMsgs.contributions_contribitionHasBothIdAndType(T_MyModule25#contributeWot)) {
			RegistryBuilder().addModule(T_MyModule25#).build
		}  
	}

	Void testContribDoesNotDefineServiceId() {
		verifyIocErrMsg(ErrMsgs.contributionMethodDoesNotDefineServiceId(T_MyModule26#cont)) {
			RegistryBuilder().addModule(T_MyModule26#).build
		}  
	}

	Void testErrWhenServiceIdNoExist() {
		verifySrvNotFoundErrMsg(ErrMsgs.contributionServiceNotFound("wotever", T_MyModule27#cont)) {
			RegistryBuilder().addModule(T_MyModule27#).build
		}  
	}

	Void testErrWhenServiceTypeNoExist() {
		verifySrvNotFoundErrMsg(ErrMsgs.contributionServiceNotFound("sys::Int", T_MyModule28#cont)) {
			RegistryBuilder().addModule(T_MyModule28#).build
		}  
	}

	Void testNoErrWhenContibIsOptional() {
		RegistryBuilder().addModule(T_MyModule29#).build
	}
	
	Void testWhenNoConfigDefined() {
		scope := threadScope { it.addModule(T_MyModule52#) }
		scope.serviceByType(T_MyService31#)
		scope.serviceById(T_MyService31#.qname)
	}
}

@Js
internal const class T_MyModule24 {
	@Contribute
	static Void contributeWot(Obj config) { }
}

@Js
internal const class T_MyModule25 {
	@Contribute { serviceId="wotever"; serviceType=T_MyModule25# }
	static Void contributeWot(Configuration config) { }
}

@Js
internal const class T_MyModule26 {
	@Contribute
	static Void cont(Configuration config) { }
}

@Js
internal const class T_MyModule27 {
	@Contribute{serviceId="wotever"}
	static Void cont(Configuration config) { }
}

@Js
internal const class T_MyModule28 {
	@Contribute{serviceType=Int#}
	static Void cont(Configuration config) { }
}

@Js
internal const class T_MyModule29 {
	@Contribute{serviceType=Int#; optional=true}
	static Void cont(Configuration config) { }
}

@Js
internal const class T_MyModule52 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService31#)
	}
}
@Js
internal mixin T_MyService31 { }
@Js
internal class T_MyService31Impl : T_MyService31 {
	new make(DependencyProvider[] config) { }
}

@Js
internal const class T_MyModule106 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService76#) { withId("s76") }
	}
	@Contribute { serviceId="s76"}
	static Void contributeWot(Configuration config) { }
}

@Js
internal class T_MyService76 {
	new make() { }
}