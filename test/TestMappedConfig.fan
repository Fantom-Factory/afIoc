
internal class TestMappedConfig : IocTest {
	
	Void testErrIfConfigIsGeneric() {
		reg := RegistryBuilder().addModule(T_MyModule43#).build.startup
		verifyErrMsg(IocMessages.mappedConfigTypeIsGeneric(Map#, "s27")) {
			reg.serviceById("s27")
		}
	}

	Void testBasicConfig() {
		reg := RegistryBuilder().addModule(T_MyModule44#).build.startup
		s28 := reg.serviceById("s28") as T_MyService28
		verifyEq(s28.config, Str:Str["wot":"ever", "wot2":"ever2"])
	}

	Void testBasicConfigViaBuilder() {
		reg := RegistryBuilder().addModule(T_MyModule45#).build.startup
		s28 := reg.serviceById("s28") as T_MyService28
		verifyEq(s28.config, Str:Str["wot":"ever", "wot2":"ever2", "ASS!":"ASS!"])
	}

	Void testConfigMethodInjection() {
		reg := RegistryBuilder().addModule(T_MyModule46#).build.startup
		s28 := reg.serviceById("s28") as T_MyService28
		verifyEq(s28.config, Str:Str["wot":"ASS!"])
	}

	Void testAddingWrongKeyType() {
		reg := RegistryBuilder().addModule(T_MyModule47#).build.startup
		verifyErrMsg(IocMessages.mappedConfigTypeMismatch("key", Int#, Type#)) {
			s74 := reg.serviceById("s74-a") as T_MyService74
		}
	}

	Void testAddingWrongValueType() {
		reg := RegistryBuilder().addModule(T_MyModule47#).build.startup
		verifyErrMsg(IocMessages.mappedConfigTypeMismatch("value", Int#, Type#)) {
			s74 := reg.serviceById("s74-b") as T_MyService74
		}
	}

	Void testKeyValueTypeCoercion() {
		reg := RegistryBuilder().addModule(T_MyModule47#).build.startup
		s68 := reg.serviceById("s68") as T_MyService68
		verifyEq(s68.config[68], "42")	
	}

	Void testMappedConfigAutobuild() {
		reg := RegistryBuilder().addModule(T_MyModule48#).build.startup
		s28 := reg.serviceById("s28") as T_MyService28
		verifyEq(s28.config, Str:Str["judge":"ASS!"])
	}

	Void testEmptyMapCreatedWhenNoContribsFound() {
		reg := RegistryBuilder().addModule(T_MyModule49#).build.startup
		s28 := reg.serviceById("s28") as T_MyService28
		verifyEq(s28.config, Str:Str[:])
	}
	
	Void testWrongConfig() {
		reg := RegistryBuilder().addModule(T_MyModule50#).build.startup
		verifyErrMsg(IocMessages.providerMethodArgDoesNotFit(MappedConfig#, OrderedConfig#)) {
			reg.serviceById("s28")
		}
	}	

	Void testEmptyListMapValueCanBeOfTypeObj() {
		reg := RegistryBuilder().addModule(T_MyModule51#).build.startup
		s29 := reg.serviceById("s29") as T_MyService29
		verifyEq(s29.config["key"], Str[,])
	}

	Void testStrKeyMapsAreCaseInSensitive() {
		reg := RegistryBuilder().addModule(T_MyModule44#).build.startup
		s28 := reg.serviceById("s28") as T_MyService28
		verifyEq(s28.config.getOrThrow("WOT"), "ever")
		verifyEq(s28.config.getOrThrow("WOT2"), "ever2")
	}

	// ---- test overrides ------------------------------------------------------------------------
	
	Void testOverride1() {
		reg := RegistryBuilder().addModule(T_MyModule62#).build.startup
		s28 := reg.serviceById("s28") as T_MyService28
		verifyEq(s28.config.size, 1)
		verifyEq(s28.config["key"], "value2")
	}

	Void testOverride2() {
		reg := RegistryBuilder().addModule(T_MyModule62#).addModule(T_MyModule63#).build.startup
		s28 := reg.serviceById("s28") as T_MyService28
		verifyEq(s28.config.size, 1)
		verifyEq(s28.config["key"], "value3")
	}

	Void testOverrideMustExist1() {
		reg := RegistryBuilder().addModule(T_MyModule64#).build.startup
		verifyErrMsg(IocMessages.contribOverrideDoesNotExist("non-exist", "over1")) {
			reg.serviceById("s28")
		}
	}

	Void testOverrideMustExist2() {
		reg := RegistryBuilder().addModule(T_MyModule65#).build.startup
		verifyErrMsg(IocMessages.contribOverrideDoesNotExist("non-exist", "over2")) {
			reg.serviceById("s28")
		}
	}

	Void testOverrideWithObjKeys() {
		reg := RegistryBuilder().addModule(T_MyModule66#).build.startup
		s46 := reg.serviceById("s46") as T_MyService46
		verifyEq(s46.config.size, 1)
		verifyEq(s46.config[Str#], "value3")
	}

	Void testCannotAddKeyTwice() {
		reg := RegistryBuilder().addModule(T_MyModule67#).build.startup
		verifyErrMsg(IocMessages.configMappedKeyAlreadyDefined(Str#.toStr)) {
			reg.serviceById("s46")
		}
	}

	Void testCannotOverrideTwice() {
		reg := RegistryBuilder().addModule(T_MyModule68#).build.startup
		verifyErrMsg(IocMessages.configOverrideKeyAlreadyDefined(Str#.toStr, Uri#.toStr)) {
			reg.serviceById("s46")
		}
	}

	Void testOverrideCannotReuseKey() {
		reg := RegistryBuilder().addModule(T_MyModule73#).build.startup
		verifyErrMsg(IocMessages.configOverrideKeyAlreadyExists(Str#.toStr)) {
			reg.serviceById("s46")
		}
	}

	Void testOverrideCannotReuseOverrideKey() {
		reg := RegistryBuilder().addModule(T_MyModule74#).build.startup
		verifyErrMsg(IocMessages.configOverrideKeyAlreadyExists(Uri#.toStr)) {
			reg.serviceById("s46")
		}
	}
	
	Void testOverrideKeysCanBeStrs() {
		reg := RegistryBuilder().addModule(T_MyModule82#).build.startup
		s68 := reg.serviceById("s68") as T_MyService68
		verifyEq(s68.config.size, 1)
		verifyEq(s68.config[69], "crowd")
	}

	// ---- test null values ----------------------------------------------------------------------

	Void testNullValue() {
		reg := RegistryBuilder().addModule(T_MyModule02#).build.startup
		s10 := (T_MyService10) reg.serviceById("s10")
		verifyEq(s10.config.size, 1)
		verifyEq(s10.config["wot"], null)		
	}

	Void testNullValueNotAllowed() {
		reg := RegistryBuilder().addModule(T_MyModule02#).build.startup
		verifyErrMsg(IocMessages.mappedConfigTypeMismatch("value", null, Str#)) {
			s28 := (T_MyService28) reg.serviceById("s28")
		}
	}

	Void testCanOverrideWithNull() {
		reg := RegistryBuilder().addModule(T_MyModule02#).build.startup
		s10 := (T_MyService10) reg.serviceById("s10b")
		verifyEq(s10.config.size, 1)
		verifyEq(s10.config["wot"], null)		
	}	

	// ---- test remove ---------------------------------------------------------------------------
	
	Void testRemove() {
		reg := RegistryBuilder().addModule(T_MyModule95#).build.startup
		s28 := reg.serviceById("s28") as T_MyService28
		verifyEq(s28.config.size, 0)
	}
}

internal class T_MyModule02 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService10#).withId("s10")
		binder.bind(T_MyService28#).withId("s28")
		binder.bind(T_MyService10#).withId("s10b")
	}
	@Contribute{ serviceId="s10" }
	static Void cont10(MappedConfig config) {
		config["wot"] = null
	}	
	@Contribute{ serviceId="s28" }
	static Void cont28(MappedConfig config) {
		config.set("wot", null)
	}	
	@Contribute{ serviceId="s10b" }
	static Void cont10b(MappedConfig config) {
		config.set("wot", "ever")
		config.setOverride("wot", null, "wot-null")
	}	
}

internal class T_MyService10 {
	Str:Str? config
	new make(Str:Str? config) {
		this.config = config
	}
}

internal class T_MyModule43 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService27#).withId("s27")
	}
	
	@Contribute{ serviceId="s27" }
	static Void cont(MappedConfig config) {
		config.set("wot", "ever")
	}
}

internal class T_MyService27 {
	new make(Map config) { }
}

internal class T_MyModule44 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService28#).withId("s28")
	}
	@Contribute{ serviceId="s28" }
	static Void cont(MappedConfig config) {
		config.set("wot", "ever")
	}
	@Contribute{ serviceId="s28" }
	static Void cont2(MappedConfig config) {
		config.set("wot2", "ever2")
	}
}

internal class T_MyService28 {
	Str:Str config
	new make(Str:Str config) {
		this.config = config
	}
}

internal class T_MyModule45 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService02#).withId("s2")
	}
	@Build
	static T_MyService28 buildS28(Str:Str str, T_MyService02 s2) {
		str[s2.kick] = s2.kick
		return T_MyService28(str)
	}
	@Contribute{ serviceId="s28" }
	static Void cont(MappedConfig config) {
		config.set("wot", "ever")
	}
	@Contribute{ serviceId="s28" }
	static Void cont2(MappedConfig config) {
		config.set("wot2", "ever2")
	}
}

internal class T_MyModule46 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService02#).withId("s2")
		binder.bind(T_MyService28#).withId("s28")
	}
	@Contribute{ serviceId="s28" }
	static Void cont(MappedConfig config, T_MyService02 s2) {
		config.set("wot", s2.kick)
	}
}

internal class T_MyModule47 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService74#).withId("s74-a")
		binder.bind(T_MyService74#).withId("s74-b")
		binder.bind(T_MyService68#).withId("s68")
	}
	@Contribute{ serviceId="s74-a" }
	static Void cont1(MappedConfig config) {
		config[68] = T_MyModule47#	// wrong key type 
	}
	@Contribute{ serviceId="s74-b" }
	static Void cont2(MappedConfig config) {
		config[T_MyModule47#] = 68	// wrong value type 
	}
	@Contribute{ serviceId="s68" }
	static Void cont3(MappedConfig config) {
		config["68"] = 42	// coerce Int <=> Str 
	}
}

internal class T_MyModule48 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService28#).withId("s28")
	}
	@Contribute{ serviceId="s28" }
	static Void cont(MappedConfig config) {
		config.set("judge", config.autobuild(T_MyService02#)->kick)
	}
}

internal class T_MyModule49 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService28#).withId("s28")
	}	
}

internal class T_MyModule50 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService28#).withId("s28")
	}
	@Contribute{ serviceId="s28" }
	static Void cont(OrderedConfig config) {
		config.add(67)
	}
}

internal class T_MyModule51 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService29#).withId("s29")
	}
	@Contribute{ serviceId="s29" }
	static Void cont(MappedConfig config) {
		config.set("key", [,])
	}
}

internal class T_MyService29 {
	Str:Str[] config
	new make(Str:Str[] config) {
		this.config = config
	}
}

internal class T_MyModule62 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService28#).withId("s28")
	}
	@Contribute
	static Void contributeS28(MappedConfig config) {
		config.set("key", "value")
		config.setOverride("key", "value2", "over1")
	}
}

internal class T_MyModule63 {
	@Contribute
	static Void contributeS28(MappedConfig config) {
		config.setOverride("over1", "value3", "over2")
	}
}

internal class T_MyModule64 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService28#).withId("s28")
	}
	@Contribute
	static Void contributeS28(MappedConfig config) {
		config.set("key", "value")
		config.setOverride("non-exist", "value2", "over1")
	}
}

internal class T_MyModule65 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService28#).withId("s28")
	}
	@Contribute
	static Void contributeS28(MappedConfig config) {
		config.set("key", "value")
		config.setOverride("key", "value2", "over1")
		config.setOverride("non-exist", "value3", "over2")
	}
}

internal class T_MyModule66 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService46#).withId("s46")
	}
	@Contribute
	static Void contributeS46(MappedConfig config) {
		config.set(Str#, "value1")
		config.setOverride(Str#, "value2", Uri#)
		config.setOverride(Uri#, "value3", File#)
	}
}

internal class T_MyModule67 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService46#).withId("s46")
	}
	@Contribute
	static Void contributeS46(MappedConfig config) {
		config.set(Str#, "once")
		config.set(Str#, "twice")
	}
}

internal class T_MyModule68 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService46#).withId("s46")
	}
	@Contribute
	static Void contributeS46(MappedConfig config) {
		config.set(Str#, "once")
		config.setOverride(Str#, "twice", Uri#)
		config.setOverride(Str#, "thrice", File#)
	}
}

internal class T_MyModule73 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService46#).withId("s46")
	}
	@Contribute
	static Void contributeS46(MappedConfig config) {
		config.set(Str#, "once")
		config.setOverride(Str#, "twice", Uri#)
		config.setOverride(Uri#, "thrice", Str#)	// attempt to re-use an existing key
	}
}

internal class T_MyModule74 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService46#).withId("s46")
	}
	@Contribute
	static Void contributeS46(MappedConfig config) {
		config.set(Str#, "once")
		config.setOverride(Str#, "twice", Uri#)
		config.setOverride(Uri#, "thrice", Uri#)	// attempt to re-use an existing override key
	}
}

internal class T_MyService46 {
	Type:Str config
	new make(Type:Str config) {
		this.config = config
	}
}

internal class T_MyModule82 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService68#).withId("s68")
	}
	@Contribute
	static Void contributeS68(MappedConfig config) {
		config.set(69, "dude")	// use Str override keys
		config.setOverride(69, "dude dude", "+1")
		config.setOverride("+1", "crowd", "+2")
	}
}

internal class T_MyService68 {
	Int:Str config
	new make(Int:Str config) {
		this.config = config
	}
}

internal class T_MyService74 {
	Type:Type config
	new make(Type:Type config) {
		this.config = config
	}
}

@SubModule{ modules=[T_MyModule62#] }
internal class T_MyModule95 {
	@Contribute { serviceType=T_MyService28# }
	static Void remove(MappedConfig config) {
		config.remove("over1", "remove")
	}
}