
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

	Void testAddingWrongContribV2() {
		reg := RegistryBuilder().addModule(T_MyModule47#).build.startup
		verifyErrMsg(IocMessages.mappedConfigTypeMismatch("value", Int#, Str#)) {
			s28 := reg.serviceById("s28") as T_MyService28
		}
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
}

internal class T_MyModule43 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService27#).withId("s27")
	}
	
	@Contribute{ serviceId="s27" }
	static Void cont(MappedConfig config) {
		config.addMapped("wot", "ever")
	}
}

internal class T_MyService27 {
	new make(Map config) { }
}

internal class T_MyModule44 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService28#).withId("s28")
	}
	@Contribute{ serviceId="s28" }
	static Void cont(MappedConfig config) {
		config.addMapped("wot", "ever")
	}
	@Contribute{ serviceId="s28" }
	static Void cont2(MappedConfig config) {
		config.addMapped("wot2", "ever2")
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
		binder.bindImpl(T_MyService2#).withId("s2")
	}
	@Build
	static T_MyService28 buildS28(Str:Str str, T_MyService2 s2) {
		str[s2.kick] = s2.kick
		return T_MyService28(str)
	}
	@Contribute{ serviceId="s28" }
	static Void cont(MappedConfig config) {
		config.addMapped("wot", "ever")
	}
	@Contribute{ serviceId="s28" }
	static Void cont2(MappedConfig config) {
		config.addMapped("wot2", "ever2")
	}
}

internal class T_MyModule46 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService2#).withId("s2")
		binder.bindImpl(T_MyService28#).withId("s28")
	}
	@Contribute{ serviceId="s28" }
	static Void cont(MappedConfig config, T_MyService2 s2) {
		config.addMapped("wot", s2.kick)
	}
}

internal class T_MyModule47 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService28#).withId("s28")
	}
	@Contribute{ serviceId="s28" }
	static Void cont(MappedConfig config) {
		config.addMapped("wot", 69)
	}
}

internal class T_MyModule48 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService28#).withId("s28")
	}
	@Contribute{ serviceId="s28" }
	static Void cont(MappedConfig config) {
		config.addMapped("judge", config.autobuild(T_MyService2#)->kick)
	}
}

internal class T_MyModule49 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService28#).withId("s28")
	}	
}

internal class T_MyModule50 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService28#).withId("s28")
	}
	@Contribute{ serviceId="s28" }
	static Void cont(OrderedConfig config) {
		config.addUnordered(67)
	}
}

internal class T_MyModule51 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService29#).withId("s29")
	}
	@Contribute{ serviceId="s29" }
	static Void cont(MappedConfig config) {
		config.addMapped("key", [,])
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
		binder.bindImpl(T_MyService28#).withId("s28")
	}
	@Contribute
	static Void contributeS28(MappedConfig config) {
		config.addMapped("key", "value")
		config.addOverride("key", "over1", "value2")
	}
}

internal class T_MyModule63 {
	@Contribute
	static Void contributeS28(MappedConfig config) {
		config.addOverride("over1", "over2", "value3")
	}
}

internal class T_MyModule64 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService28#).withId("s28")
	}
	@Contribute
	static Void contributeS28(MappedConfig config) {
		config.addMapped("key", "value")
		config.addOverride("non-exist", "over1", "value2")
	}
}

internal class T_MyModule65 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService28#).withId("s28")
	}
	@Contribute
	static Void contributeS28(MappedConfig config) {
		config.addMapped("key", "value")
		config.addOverride("key", "over1", "value2")
		config.addOverride("non-exist", "over2", "value3")
	}
}

internal class T_MyModule66 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService46#).withId("s46")
	}
	@Contribute
	static Void contributeS46(MappedConfig config) {
		config.addMapped(Str#, "value1")
		config.addOverride(Str#, Uri#, "value2")
		config.addOverride(Uri#, File#, "value3")
	}
}

internal class T_MyModule67 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService46#).withId("s46")
	}
	@Contribute
	static Void contributeS46(MappedConfig config) {
		config.addMapped(Str#, "once")
		config.addMapped(Str#, "twice")
	}
}

internal class T_MyModule68 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService46#).withId("s46")
	}
	@Contribute
	static Void contributeS46(MappedConfig config) {
		config.addMapped(Str#, "once")
		config.addOverride(Str#, Uri#, "twice")
		config.addOverride(Str#, File#, "thrice")
	}
}

internal class T_MyModule73 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService46#).withId("s46")
	}
	@Contribute
	static Void contributeS46(MappedConfig config) {
		config.addMapped(Str#, "once")
		config.addOverride(Str#, Uri#, "twice")
		config.addOverride(Uri#, Str#, "thrice")	// attempt to re-use an existing key
	}
}

internal class T_MyModule74 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService46#).withId("s46")
	}
	@Contribute
	static Void contributeS46(MappedConfig config) {
		config.addMapped(Str#, "once")
		config.addOverride(Str#, Uri#, "twice")
		config.addOverride(Uri#, Uri#, "thrice")	// attempt to re-use an existing override key
	}
}

internal class T_MyService46 {
	Type:Str config
	new make(Type:Str config) {
		this.config = config
	}
}