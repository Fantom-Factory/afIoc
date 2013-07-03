
internal class TestOrderedConfig : IocTest {
	
	Void testErrIfConfigIsGeneric() {
		reg := RegistryBuilder().addModule(T_MyModule31#).build.startup
		verifyErrMsg(IocMessages.orderedConfigTypeIsGeneric(List#, "s20")) {
			reg.serviceById("s20")
		}
	}

	Void testBasicConfig() {
		reg := RegistryBuilder().addModule(T_MyModule30#).build.startup
		s19 := reg.serviceById("s19") as T_MyService19
		verifyEq(s19.config, Str["ever", "wot"])
	}

	Void testBasicConfigViaBuilder() {
		reg := RegistryBuilder().addModule(T_MyModule32#).build.startup
		s21 := reg.serviceById("s21") as T_MyService21
		verifyEq(s21.config, Str["ever", "wot", "ASS!"])
	}

	Void testConfigMethodInjection() {
		reg := RegistryBuilder().addModule(T_MyModule33#).build.startup
		s21 := reg.serviceById("s21") as T_MyService21
		verifyEq(s21.config, Str["wot", "ASS!"])
	}

	Void testAddingWrongContribV2() {
		reg := RegistryBuilder().addModule(T_MyModule35#).build.startup
		verifyErrMsg(IocMessages.orderedConfigTypeMismatch(Int#, Str#)) {
			s22 := reg.serviceById("s22") as T_MyService22
		}
	}

	Void testOrderedConfigAutobuild() {
		reg := RegistryBuilder().addModule(T_MyModule36#).build.startup
		s23 := reg.serviceById("s23") as T_MyService23
		verifyEq(s23.config, Str["ASS!"])
	}

	Void testEmptyListCreatedWhenNoContribsFound() {
		reg := RegistryBuilder().addModule(T_MyModule38#).build.startup
		s23 := reg.serviceById("s23") as T_MyService23
		verifyEq(s23.config, Str[,])
	}

	Void testWrongConfig() {
		reg := RegistryBuilder().addModule(T_MyModule34#).build.startup
		verifyErrMsg(IocMessages.providerMethodArgDoesNotFit(OrderedConfig#, MappedConfig#)) {
			reg.serviceById("s21")
		}
	}

	Void testPlaceholderOrder() {
		reg := RegistryBuilder().addModule(T_MyModule86#).build.startup
		s23 := reg.serviceById("s23") as T_MyService23
		
		verifyEq(s23.config[0], "simple")
		verifyEq(s23.config[1], "preflight")
		verifyEq(s23.config[2], "essays1")
		verifyEq(s23.config[3], "essays2")
		verifyEq(s23.config[4], "index")
	}

	// ---- test overrides ------------------------------------------------------------------------
	
	Void testOverride1() {
		reg := RegistryBuilder().addModule(T_MyModule69#).build.startup
		s23 := reg.serviceById("s23") as T_MyService23
		verifyEq(s23.config.size, 1)
		verifyEq(s23.config[0], "value2")
	}

	Void testOverride2() {
		reg := RegistryBuilder().addModule(T_MyModule70#).build.startup
		s23 := reg.serviceById("s23") as T_MyService23
		verifyEq(s23.config.size, 1)
		verifyEq(s23.config[0], "value3")
	}

	Void testOverrideMustExist1() {
		reg := RegistryBuilder().addModule(T_MyModule71#).build.startup
		verifyErrMsg(IocMessages.contribOverrideDoesNotExist("non-exist", "over1")) {
			reg.serviceById("s23")
		}
	}

	Void testOverrideMustExist2() {
		reg := RegistryBuilder().addModule(T_MyModule72#).build.startup
		verifyErrMsg(IocMessages.contribOverrideDoesNotExist("non-exist", "over2")) {
			reg.serviceById("s23")
		}
	}
	
	// ---- test null values ----------------------------------------------------------------------

	Void testNullValue() {
		reg := RegistryBuilder().addModule(T_MyModule87#).build.startup
		s71 := (T_MyService71) reg.serviceById("s71")
		verifyEq(s71.config.size, 1)
		verifyEq(s71.config[0], null)		
	}

	Void testNullValueNotAllowed() {
		reg := RegistryBuilder().addModule(T_MyModule87#).build.startup
		verifyErrMsg(IocMessages.orderedConfigTypeMismatch(null, Str#)) {
			s19 := (T_MyService28) reg.serviceById("s19")
		}
	}

	Void testCanOverrideWithNull() {
		reg := RegistryBuilder().addModule(T_MyModule87#).build.startup
		s71 := (T_MyService71) reg.serviceById("s71")
		verifyEq(s71.config.size, 1)
		verifyEq(s71.config[0], null)		
	}	

	// ---- test null values ----------------------------------------------------------------------

	Void testUnorderedIsOrdered() {
		reg := RegistryBuilder().addModule(T_MyModule89#).build.startup
		s73 := (T_MyService73) reg.serviceById("s73")
		Env.cur.err.printLine(s73.config)
		verifyEq(s73.config.size, 10)
		verifyEq(s73.config[0], 1)
		verifyEq(s73.config[1], 2)
		verifyEq(s73.config[2], 3)
		verifyEq(s73.config[3], 4)
		verifyEq(s73.config[4], 5)
		verifyEq(s73.config[5], 6)
		verifyEq(s73.config[6], 7)
		verifyEq(s73.config[7], 8)
		verifyEq(s73.config[8], 9)
		verifyEq(s73.config[9], 10)
	}
}


internal class T_MyService71 {
	Str?[] config
	new make(Str?[] config) {
		this.config = config
	}
}

internal class T_MyModule87 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService71#).withId("s71")
		binder.bindImpl(T_MyService19#).withId("s19")
		binder.bindImpl(T_MyService71#).withId("s71b")
	}
	@Contribute{ serviceId="s71" }
	static Void cont10(OrderedConfig config) {
		config.addOrdered("wot", null)
	}	
	@Contribute{ serviceId="s19" }
	static Void cont28(OrderedConfig config) {
		config.addOrdered("wot", null)
	}	
	@Contribute{ serviceId="s71b" }
	static Void cont10b(OrderedConfig config) {
		config.addOrdered("wot", "ever")
		config.addOverride("wot", "wot-null", null)
	}	
}

internal class T_MyModule30 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService19#).withId("s19")
	}
	@Contribute{ serviceId="s19" }
	static Void cont(OrderedConfig config) {
		config.addUnordered("wot")
	}
	@Contribute{ serviceId="s19" }
	static Void cont2(OrderedConfig config) {
		config.addUnordered("ever")
	}
}

internal class T_MyService19 {
	Str[] config
	new make(Str[] config) {
		this.config = config
	}
}

internal class T_MyModule31 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService20#).withId("s20")
	}
	
	@Contribute{ serviceId="s20" }
	static Void cont(OrderedConfig config) {
		config.addUnordered("wot")
	}
}

internal class T_MyService20 {
	new make(List config) { }
}

internal class T_MyModule32 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService02#).withId("s2")
	}
	
	@Build
	static T_MyService21 buildS21(Str[] str, T_MyService02 s2) {
		T_MyService21(str.add(s2.kick))
	}
	
	@Contribute{ serviceId="s21" }
	static Void cont(OrderedConfig config) {
		config.addUnordered("wot")
	}
	@Contribute{ serviceId="s21" }
	static Void cont2(OrderedConfig config) {
		config.addUnordered("ever")
	}
}

internal class T_MyService21 {
	Str[] config
	new make(Str[] config) {
		this.config = config
	}
}

internal class T_MyModule33 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService02#).withId("s2")
		binder.bindImpl(T_MyService21#).withId("s21")
	}
	
	@Contribute{ serviceId="s21" }
	static Void cont(OrderedConfig config, T_MyService02 s2) {
		config.addUnordered("wot")
		config.addUnordered(s2.kick)
	}
}

internal class T_MyModule34 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService21#).withId("s21")
	}
	@Contribute{ serviceId="s21" }
	static Void cont(MappedConfig config) {
		config.addMapped(69 ,69)
	}
}

internal class T_MyModule35 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService22#).withId("s22")
	}
	
	@Contribute{ serviceId="s22" }
	static Void cont(OrderedConfig config) {
		config.addUnordered(69)
	}
}

internal class T_MyService22 {
	Str[] config
	new make(Str[] config) {
		this.config = config
	}
}

internal class T_MyModule36 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService23#).withId("s23")
	}
	
	@Contribute{ serviceId="s23" }
	static Void cont(OrderedConfig config) {
		config.addUnordered(config.autobuild(T_MyService02#)->kick)
	}
}

internal class T_MyService23 {
	Str[] config
	new make(Str[] config) {
		this.config = config
	}
}

internal class T_MyModule38 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService23#).withId("s23")
	}	
}

internal class T_MyModule69 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService23#).withId("s23")
	}
	@Contribute
	static Void contributeS23(OrderedConfig config) {
		config.addOrdered("key", "value1")
		config.addOverride("key", "over1", "value2")
	}
}

internal class T_MyModule70 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService23#).withId("s23")
	}
	@Contribute
	static Void contributeS23(OrderedConfig config) {
		config.addOrdered("key", "value1")
		config.addOverride("key", "over1", "value2")
		config.addOverride("over1", "over2", "value3")
	}
}

internal class T_MyModule71 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService23#).withId("s23")
	}
	@Contribute
	static Void contributeS23(OrderedConfig config) {
		config.addOrdered("key", "value")
		config.addOverride("non-exist", "over1", "value2")
	}
}

internal class T_MyModule72 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService23#).withId("s23")
	}
	@Contribute
	static Void contributeS23(OrderedConfig config) {
		config.addOrdered("key", "value")
		config.addOverride("key", "over1", "value2")
		config.addOverride("non-exist", "over2", "value3")
	}
}

internal class T_MyModule86 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService23#).withId("s23")
	}
	@Contribute
	static Void contributeS23(OrderedConfig config) {		
		config.addOrderedPlaceholder("filters")
		config.addOrderedPlaceholder("routes")
		
		config.addOrdered("corsFilter", "simple", 	  ["before: routes"])
		config.addOrdered("corsFilter2", "preflight", ["before: routes"])

		// we would expect these to appear *after* the 2 filters above
		config.addUnordered("essays1")
		config.addUnordered("essays2")
		config.addUnordered("index")
	}
}

internal class T_MyModule89 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService73#).withId("s73")
	}
	@Contribute
	static Void contributeS73(OrderedConfig config) {		
		config.addUnordered(1)
		config.addUnordered(2)
		config.addUnordered(3)
		config.addUnordered(4)
		config.addUnordered(5)
		config.addUnordered(6)
		config.addUnordered(7)
		config.addUnordered(8)
		config.addUnordered(9)
		config.addUnordered(10)
	}
}

internal class T_MyService73 {
	Int[] config
	new make(Int[] config) {
		this.config = config
	}
}