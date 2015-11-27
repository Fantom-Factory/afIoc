
@Js
internal class TestRegistryBuilder : IocTest {

	Void testBannerText() {
		bob := RegistryBuilder()
		bob.options.set("afIoc.bannerText","align right")
		bob.build
		
		bob = RegistryBuilder()
		bob.options.set("afIoc.bannerText","I'm completely operational and all my circuits are  functioning perfectly. - HAL 9000")
		bob.build
	}

	Void testRegistryMeta() {
		bob := RegistryBuilder()
		bob.options.set("hereMeNow", true)
		reg := bob.build
		opts := (RegistryMeta) reg.rootScope.serviceByType(RegistryMeta#)
		verify(opts.options["hereMeNow"])
	}

	Void testRegistryOptionsCanBeNull() {
		bob := RegistryBuilder()
		bob.options.set("meNull", null)
		reg := bob.build
		opts := (RegistryMeta) reg.rootScope.serviceByType(RegistryMeta#)
		verify(opts.options.containsKey("meNull"))
		verifyNull(opts.options["meNull"])
	}

	Void testRegistryOptionValues() {
		bob := RegistryBuilder()
		bob.options["afIoc.bannerText"] = true
		verifyIocErrMsg(ErrMsgs.regBuilder_invalidRegistryValue("afIoc.bannerText", Bool#, Str#)) { 
			bob.build
		}
	}
	
	Void testServiceDefWithArgs() {
		reg := threadScope { addModule(T_MyModule108#) }
		ser := (T_MyService102) reg.serviceById("s102")
		verifyEq(ser.a, "Judge")
		verifyEq(ser.b, "Dredd")

		ovr := (T_MyService102) reg.serviceById("o102")
		verifyEq(ovr.a, "Sexy")
		verifyEq(ovr.b, "Anderson")
	}
	
	Void testBindImplFindsImpl() {
		reg := threadScope { addModule(T_MyModule13#) }
		reg.serviceById("yo")
	}

	Void testBindImplFitsMixin() {
		reg := threadScope { addModule(T_MyModule14#) }

		// this was thrown during regBuilding, but has since moved to service building (due to Autobuilder becoming a service)
		verifyIocErrMsg(ErrMsgs.autobuilder_bindImplNotClass(T_MyService11Impl#)) {
			reg.serviceById("yo")
		}
		
		// this used to hang until we reset ServiceStore.building on Err
		verifyIocErrMsg(ErrMsgs.autobuilder_bindImplNotClass(T_MyService11Impl#)) {
			reg.serviceByType(T_MyService11#)
		}
	}

	Void testBindImplFitsMixinErrIfNot() {
		// this was thrown during regBuilding, but has since moved to service building (due to Autobuilder becoming a service)
		reg := threadScope { addModule(T_MyModule15#) }
		verifyIocErrMsg(ErrMsgs.autobuilder_bindImplDoesNotFit(T_MyService01#, T_MyService02#)) {   			
			reg.serviceById(T_MyService01#.qname)
		}
		verifyIocErrMsg(ErrMsgs.autobuilder_bindImplDoesNotFit(T_MyService01#, T_MyService02#)) {   			
			reg.serviceByType(T_MyService01#)
		}
	}
	
	Void testContribFuncsViaId() {
		s21 := threadScope { 
			addService(T_MyService21#).withId("s21") 
			contributeToService("s21") |Configuration config| {
				config.add("wot")
			}
		}.serviceById("s21") as T_MyService21
		
		verifyEq(s21.config, ["wot"])
	}

	Void testContribFuncsViaType() {
		s21 := threadScope { 
			addService(T_MyService21#).withId("s21") 
			contributeToServiceType(T_MyService21#) |Configuration config| {
				config.add("wot")
			}
		}.serviceById("s21") as T_MyService21
		
		verifyEq(s21.config, ["wot"])
	}

	Void testContribFuncInjection() {
		s21 := threadScope { 
			contributeToService("s21") |Configuration config| {
				s03 := config.scope.serviceById("s03")
				config.add(s03.typeof.name)
			}
			addService(T_MyService21#).withId("s21") 
			addService(T_MyService03#).withId("s03") 
		}.serviceById("s21") as T_MyService21
		
		verifyEq(s21.config, ["T_MyService03Impl"])
	}

	Void testBuilderFuncInjection() {
		s21 := threadScope { 
			addService(T_MyService21#).withId("s21").withBuilder |scope| {
				s03 := scope.serviceById("s03")
				return T_MyService21([s03.typeof.name])
			} 
			addService(T_MyService03#).withId("s03") 
		}.serviceById("s21") as T_MyService21
		
		verifyEq(s21.config, ["T_MyService03Impl"])
	}
}

@Js
internal const class T_MyModule108 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService102#).withCtorArgs(["Judge"]).withFieldVals([T_MyService102#b:"Dredd"]).withId("s102")
		defs.addService(T_MyService102#).withCtorArgs(["Judge"]).withFieldVals([T_MyService102#b:"Dredd"]).withId("o102")
		defs.overrideService("o102").withCtorArgs(["Sexy" ]).withFieldVals([T_MyService102#b:"Anderson"])
	}
}

@Js
internal class T_MyService102 {
	Str a
	Str b
	new make(Str a, |This|f) {
		f(this)
		this.a = a
	}
}

@Js
internal const class T_MyModule13 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService03#).withId("yo")
	}
}
@Js
internal mixin T_MyService03 { }
@Js
internal class T_MyService03Impl : T_MyService03 { }
		
@Js
internal const class T_MyModule14 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService11#).withId("yo")
	}
}

@Js
internal const class T_MyModule15 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService01#, T_MyService02#)
	}
}

@Js
internal mixin T_MyService11 { }
@Js
internal mixin T_MyService11Impl : T_MyService11 { }
