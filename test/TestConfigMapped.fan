
@Js
internal class TestConfigMapped : IocTest {
	
	Void testErrIfConfigIsGeneric() {
		scope := threadScope { addModule(T_MyModule43#) }
		verifyIocErrMsg(ErrMsgs.contributions_configTypeIsGeneric(Map#, "s27")) {
			scope.serviceById("s27")
		}
	}

	Void testBasicConfig() {
		scope := threadScope { addModule(T_MyModule44#) }
		s28 := scope.serviceById("s28") as T_MyService28
		verifyEq(s28.config, Str:Str["wot":"ever", "wot2":"ever2"])
	}

	Void testBasicConfigViaBuilder() {
		scope := threadScope { addModule(T_MyModule45#) }
		s28 := scope.serviceById(T_MyService28#.qname) as T_MyService28
		verifyEq(s28.config, Str:Str["wot":"ever", "wot2":"ever2", "ASS!":"ASS!"])
	}

	Void testConfigMethodInjection() {
		scope := threadScope { addModule(T_MyModule46#) }
		s28 := scope.serviceById("s28") as T_MyService28
		verifyEq(s28.config, Str:Str["wot":"ASS!"])
	}

	Void testAddingWrongKeyType() {
		scope := threadScope { addModule(T_MyModule47#) }
		verifyIocErrMsg(ErrMsgs.contributions_configTypeMismatch("key", Int#, Type#)) {
			s74 := scope.serviceById("s74-a") as T_MyService74
		}
	}

	Void testAddingWrongValueType() {
		scope := threadScope { addModule(T_MyModule47#) }
		verifyIocErrMsg(ErrMsgs.contributions_configTypeMismatch("value", Int#, Type#)) {
			s74 := scope.serviceById("s74-b") as T_MyService74
		}
	}

	Void testKeyValueTypeCoercion() {
		scope := threadScope { addModule(T_MyModule47#) }
		s68 := scope.serviceById("s68") as T_MyService68
		verifyEq(s68.config[68], "42")	
	}

	Void testMappedConfigAutobuild() {
		scope := threadScope { addModule(T_MyModule48#) }
		s28 := scope.serviceById("s28") as T_MyService28
		verifyEq(s28.config, Str:Str["judge":"ASS!"])
	}

	Void testEmptyMapCreatedWhenNoContribsFound() {
		scope := threadScope { addModule(T_MyModule49#) }
		s28 := scope.serviceById("s28") as T_MyService28
		verifyEq(s28.config, Str:Str[:])
	}

	Void testEmptyListMapValueCanBeOfTypeObj() {
		scope := threadScope { addModule(T_MyModule51#) }
		s29 := scope.serviceById("s29") as T_MyService29
		verifyEq(s29.config["key"], Type[,])
	}

	Void testLotsOfNonStrKeys() {
		scope := threadScope { addModule(T_MyModule74#) }
		s46 := scope.serviceById("s46-2") as T_MyService46
		verifyEq(s46.config[Str#], "1")
		verifyEq(s46.config[Uri#], "2")
		verifyEq(s46.config[Buf#], "3")
	}

	// ---- test overrides ------------------------------------------------------------------------
	
	Void testOverride1() {
		scope := threadScope { addModule(T_MyModule62#) }
		s28 := scope.serviceById("s28") as T_MyService28
		verifyEq(s28.config.size, 1)
		verifyEq(s28.config["key"], "value2")
	}

	Void testOverride2() {
		scope := threadScope { addModule(T_MyModule62#).addModule(T_MyModule63#) }
		s28 := scope.serviceById("s28") as T_MyService28
		verifyEq(s28.config.size, 1)
		verifyEq(s28.config["key"], "value3")
	}

	Void testOverrideMustExist1() {
		scope := threadScope { addModule(T_MyModule64#) }
		verifyIocErrMsg(ErrMsgs.contributions_overrideDoesNotExist("non-exist", "over1")) {
			scope.serviceById("s28")
		}
	}

	Void testOverrideMustExist2() {
		scope := threadScope { addModule(T_MyModule65#) }
		verifyIocErrMsg(ErrMsgs.contributions_overrideDoesNotExist("non-exist", "over2")) {
			scope.serviceById("s28")
		}
	}

	Void testOverrideWithObjKeys() {
		scope := threadScope { addModule(T_MyModule66#) }
		s46 := scope.serviceById("s46") as T_MyService46
		verifyEq(s46.config.size, 1)
		verifyEq(s46.config[Str#], "value3")
	}

	Void testCannotAddKeyTwice() {
		scope := threadScope { addModule(T_MyModule67#) }
		verifyIocErrMsg(ErrMsgs.contributions_configKeyAlreadyDefined(Str#.toStr, "once")) {
			scope.serviceById("s46")
		}
	}

	Void testCannotOverrideTwice() {
		scope := threadScope { addModule(T_MyModule68#) }
		verifyIocErrMsg(ErrMsgs.contributions_configOverrideKeyAlreadyDefined(Str#.toStr, Uri#.toStr)) {
			scope.serviceById("s46")
		}
	}

	Void testOverrideCannotReuseKey() {
		scope := threadScope { addModule(T_MyModule73#) }
		verifyIocErrMsg(ErrMsgs.contributions_configOverrideKeyAlreadyExists(Str#.toStr)) {
			scope.serviceById("s46")
		}
	}

	Void testOverrideCannotReuseOverrideKey() {
		scope := threadScope { addModule(T_MyModule74#) }
		verifyIocErrMsg(ErrMsgs.contributions_configOverrideKeyAlreadyExists(Uri#.toStr)) {
			scope.serviceById("s46")
		}
	}
	
	Void testOverrideKeysCanBeStrs() {
		scope := threadScope { addModule(T_MyModule82#) }
		s68 := scope.serviceById("s68") as T_MyService68
		verifyEq(s68.config.size, 1)
		verifyEq(s68.config[69], "crowd")
	}

	// ---- test null values ----------------------------------------------------------------------

	Void testNullValue() {
		scope := threadScope { addModule(T_MyModule02#) }
		s10 := (T_MyService10) scope.serviceById("s10")
		verifyEq(s10.config.size, 1)
		verifyEq(s10.config["wot"], null)		
	}

	Void testNullValueNotAllowed() {
		scope := threadScope { addModule(T_MyModule02#) }
		verifyIocErrMsg(ErrMsgs.contributions_configTypeMismatch("value", null, Str#)) {
			s28 := (T_MyService28) scope.serviceById("s28")
		}
	}

	Void testCanOverrideWithNull() {
		scope := threadScope { addModule(T_MyModule02#) }
		s10 := (T_MyService10) scope.serviceById("s10b")
		verifyEq(s10.config.size, 1)
		verifyEq(s10.config["wot"], null)		
	}	

	// ---- test remove ---------------------------------------------------------------------------
	
	Void testRemove() {
		scope := threadScope { addModule(T_MyModule95#) }
		s28 := scope.serviceById("s28") as T_MyService28
		verifyEq(s28.config.size, 0)
	}
}

@Js
internal const class T_MyModule02 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService10#).withId("s10")
		defs.addService(T_MyService28#).withId("s28")
		defs.addService(T_MyService10#).withId("s10b")
	}
	@Contribute{ serviceId="s10" }
	static Void cont10(Configuration config) {
		config["wot"] = null
	}	
	@Contribute{ serviceId="s28" }
	static Void cont28(Configuration config) {
		config.set("wot", null)
	}	
	@Contribute{ serviceId="s10b" }
	static Void cont10b(Configuration config) {
		config.set("wot", "ever")
		config.overrideValue("wot", null, "wot-null")
	}	
}

@Js
internal class T_MyService10 {
	Str:Str? config
	new make(Str:Str? config) {
		this.config = config
	}
}

@Js
internal const class T_MyModule43 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService27#).withId("s27")
	}
	
	@Contribute{ serviceId="s27" }
	static Void cont(Configuration config) {
		config.set("wot", "ever")
	}
}

@Js
internal class T_MyService27 {
	new make(Map config) { }
}

@Js
internal const class T_MyModule44 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService28#).withId("s28")
	}
	@Contribute{ serviceId="s28" }
	static Void cont(Configuration config) {
		config.set("wot", "ever")
	}
	@Contribute{ serviceId="s28" }
	static Void cont2(Configuration config) {
		config.set("wot2", "ever2")
	}
}

@Js
internal class T_MyService28 {
	Str:Str config
	new make(Str:Str config) {
		this.config = config
	}
}

@Js
internal const class T_MyModule45 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService02#).withId("s2")
	}
	@Build
	static T_MyService28 buildS28(Str:Str str, T_MyService02 s2) {
		str[s2.kick] = s2.kick
		return T_MyService28(str)
	}
	@Contribute { serviceType=T_MyService28# }
	static Void cont(Configuration config) {
		config.set("wot", "ever")
	}
	@Contribute { serviceType=T_MyService28# }
	static Void cont2(Configuration config) {
		config.set("wot2", "ever2")
	}
}

@Js
internal const class T_MyModule46 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService02#).withId("s2")
		defs.addService(T_MyService28#).withId("s28")
	}
	@Contribute{ serviceId="s28" }
	static Void cont(Configuration config, T_MyService02 s2) {
		config.set("wot", s2.kick)
	}
}

@Js
internal const class T_MyModule47 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService74#).withId("s74-a")
		defs.addService(T_MyService74#).withId("s74-b")
		defs.addService(T_MyService68#).withId("s68")
	}
	@Contribute{ serviceId="s74-a" }
	static Void cont1(Configuration config) {
		config[68] = T_MyModule47#	// wrong key type 
	}
	@Contribute{ serviceId="s74-b" }
	static Void cont2(Configuration config) {
		config[T_MyModule47#] = 68	// wrong value type 
	}
	@Contribute{ serviceId="s68" }
	static Void cont3(Configuration config) {
		config["68"] = 42	// coerce Int <=> Str 
	}
}

@Js
internal const class T_MyModule48 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService28#).withId("s28")
	}
	@Contribute{ serviceId="s28" }
	static Void cont(Configuration config) {
		config.set("judge", config.build(T_MyService02#)->kick)
	}
}

@Js
internal const class T_MyModule49 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService28#).withId("s28")
	}	
}

@Js
internal const class T_MyModule51 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService29#).withId("s29")
	}
	@Contribute{ serviceId="s29" }
	static Void cont(Configuration config) {
		config["oop"] = [Scope#]
		config["key"] = [,]
	}
}

@Js
internal class T_MyService29 {
	Str:Type[] config
	new make(Str:Type[] config) {
		this.config = config
	}
}

@Js
internal const class T_MyModule62 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService28#).withId("s28")
	}
	@Contribute { serviceType=T_MyService28# }
	static Void contributeS28(Configuration config) {
		config.set("key", "value")
		config.overrideValue("key", "value2", "over1")
	}
}

@Js
internal const class T_MyModule63 {
	@Contribute { serviceType=T_MyService28# }
	static Void contributeS28(Configuration config) {
		config.overrideValue("over1", "value3", "over2")
	}
}

@Js
internal const class T_MyModule64 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService28#).withId("s28")
	}
	@Contribute { serviceType=T_MyService28# }
	static Void contributeS28(Configuration config) {
		config.set("key", "value")
		config.overrideValue("non-exist", "value2", "over1")
	}
}

@Js
internal const class T_MyModule65 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService28#).withId("s28")
	}
	@Contribute { serviceType=T_MyService28# }
	static Void contributeS28(Configuration config) {
		config.set("key", "value")
		config.overrideValue("key", "value2", "over1")
		config.overrideValue("non-exist", "value3", "over2")
	}
}

@Js
internal const class T_MyModule66 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService46#).withId("s46")
	}
	@Contribute { serviceType=T_MyService46# }
	static Void contributeS46(Configuration config) {
		config.set(Str#, "value1")
		config.overrideValue(Str#, "value2", Uri#)
		config.overrideValue(Uri#, "value3", File#)
	}
}

@Js
internal const class T_MyModule67 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService46#).withId("s46")
	}
	@Contribute { serviceType=T_MyService46# }
	static Void contributeS46(Configuration config) {
		config.set(Str#, "once")
		config.set(Str#, "twice")
	}
}

@Js
internal const class T_MyModule68 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService46#).withId("s46")
	}
	@Contribute { serviceType=T_MyService46# }
	static Void contributeS46(Configuration config) {
		config.set(Str#, "once")
		config.overrideValue(Str#, "twice", Uri#)
		config.overrideValue(Str#, "thrice", File#)
	}
}

@Js
internal const class T_MyModule73 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService46#).withId("s46")
	}
	@Contribute { serviceType=T_MyService46# }
	static Void contributeS46(Configuration config) {
		config.set(Str#, "once")
		config.overrideValue(Str#, "twice", Uri#)
		config.overrideValue(Uri#, "thrice", Str#)	// attempt to re-use an existing key
	}
}

@Js
internal const class T_MyModule74 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService46#).withId("s46")
		defs.addService(T_MyService46#).withId("s46-2")
	}
	@Contribute { serviceId="s46" }
	static Void contributeS46(Configuration config) {
		config.set(Str#, "once")
		config.overrideValue(Str#, "twice", Uri#)
		config.overrideValue(Uri#, "thrice", Uri#)	// attempt to re-use an existing override key
	}
	@Contribute { serviceId="s46-2" }
	static Void contributeS46_2(Configuration config) {
		config[Str#] = "1"
		config[Uri#] = "2"
		config[Buf#] = "3"
	}
}

@Js
internal class T_MyService46 {
	Type:Str config
	new make(Type:Str config) {
		this.config = config
	}
	override Str toStr() { "s46" }
}

@Js
internal const class T_MyModule82 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService68#).withId("s68")
	}
	@Contribute { serviceType=T_MyService68# }
	static Void contributeS68(Configuration config) {
		config.set(69, "dude")	// use Str override keys
		config.overrideValue(69, "dude dude", "+1")
		config.overrideValue("+1", "crowd", "+2")
	}
}

@Js
internal class T_MyService68 {
	Int:Str config
	new make(Int:Str config) {
		this.config = config
	}
}

@Js
internal class T_MyService74 {
	Type:Type config
	new make(Type:Type config) {
		this.config = config
	}
}

@Js
@SubModule{ modules=[T_MyModule62#] }
internal const class T_MyModule95 {
	@Contribute { serviceType=T_MyService28# }
	static Void remove(Configuration config) {
		config.remove("over1", "remove")
	}
}