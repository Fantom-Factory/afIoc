
internal class TestOrderedConfig : IocTest {
	
	Void testErrIfConfigIsGeneric() {
		reg := RegistryBuilder().addModule(T_MyModule31#).build.startup
		verifyIocErrMsg(IocMessages.contributions_configTypeIsGeneric(List#, "s20")) {
			reg.serviceById("s20")
		}
	}

	Void testBasicConfig() {
		reg := RegistryBuilder().addModule(T_MyModule30#).build.startup
		s19 := reg.serviceById("s19") as T_MyService19
		verifyEq(s19.config, Str["wot", "ever"])
	}

	Void testBasicConfigViaBuilder() {
		reg := RegistryBuilder().addModule(T_MyModule32#).build.startup
		s21 := reg.serviceById("s21") as T_MyService21
		verifyEq(s21.config, Str["wot", "ever", "ASS!"])
	}

	Void testConfigMethodInjection() {
		reg := RegistryBuilder().addModule(T_MyModule33#).build.startup
		s21 := reg.serviceById("s21") as T_MyService21
		verifyEq(s21.config, Str["wot", "ASS!"])
	}

	Void testAddingWrongContrib() {
		reg := RegistryBuilder().addModule(T_MyModule35#).build.startup
		verifyIocErrMsg(IocMessages.contributions_configTypeMismatch("value", Type#, Int#)) {
			s22 := reg.serviceById("s22") as T_MyService22
		}
	}

	Void testContribIsCoerced() {
		reg := RegistryBuilder().addModule(T_MyModule35#).build.startup
		s22 := reg.serviceById("s22-b") as T_MyService22
		verifyEq(s22.config[0], 69)
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
		verifyIocErrMsg(IocMessages.contributions_overrideDoesNotExist("non-exist", "over1")) {
			reg.serviceById("s23")
		}
	}

	Void testOverrideMustExist2() {
		reg := RegistryBuilder().addModule(T_MyModule72#).build.startup
		verifyIocErrMsg(IocMessages.contributions_overrideDoesNotExist("non-exist", "over2")) {
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
		verifyIocErrMsg(IocMessages.contributions_configTypeMismatch("value", null, Str#)) {
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
	
	// ---- Bug Tests -----------------------------------------------------------------------------
	
	Void testFilterBug() {
		reg := RegistryBuilder().addModule(T_MyModule92#).build.startup
		s82 := (T_MyService82) reg.serviceById("s82")
		
		// BugFix 1.3.10: fix the issue below of HttpCleanupFilter being added twice in Orderer.visit(...)
		
//-> IeAjaxCacheBustingFilter
//   visit BedSheetFilters
//   -> BedSheetFilters
//     visit HttpErrFilter
//     -> HttpErrFilter
//        visit HttpCleanupFilter
//        -> HttpCleanupFilter
//           adding HttpCleanupFilter **
//        <- HttpCleanupFilter
//        adding HttpErrFilter
//     <- HttpErrFilter
//     visit HttpCleanupFilter
//     -> HttpCleanupFilter
//        adding HttpCleanupFilter **
//     <- HttpCleanupFilter
//     adding BedSheetFilters
//   <- BedSheetFilters
//   adding IeAjaxCacheBustingFilter
//<- IeAjaxCacheBustingFilter
		
		verifyEq(s82.filters.size, 3)
		verifyEq(s82.filters[0], "HttpCleanupFilter#")
		verifyEq(s82.filters[1], "HttpErrFilter#")
		verifyEq(s82.filters[2], "IeAjaxCacheBustingFilter#")
	}

	Void testOverrideBug() {
		reg := RegistryBuilder().addModule(T_MyModule94#).build.startup
		s82 := (T_MyService82) reg.serviceById("s82")
		
		verifyEq(s82.filters.size, 2)
		verifyEq(s82.filters[0], "A")
		verifyEq(s82.filters[1], "D")		
	}

	// ---- Remove Tests --------------------------------------------------------------------------

	Void testRemove() {
		reg := RegistryBuilder().addModule(T_MyModule93#).build.startup
		s82 := (T_MyService82) reg.serviceById("s82")
		
		verifyEq(s82.filters.size, 2)
		verifyEq(s82.filters[0], "HttpCleanupFilter#")
		verifyEq(s82.filters[1], "IeAjaxCacheBustingFilter#")		
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
		binder.bind(T_MyService71#).withId("s71")
		binder.bind(T_MyService19#).withId("s19")
		binder.bind(T_MyService71#).withId("s71b")
	}
	@Contribute{ serviceId="s71" }
	static Void cont10(Configuration config) {
		config["wot"] = null
	}	
	@Contribute{ serviceId="s19" }
	static Void cont28(Configuration config) {
		config["wot"] = null
	}	
	@Contribute{ serviceId="s71b" }
	static Void cont10b(Configuration config) {
		config["wot"] = "ever"
		config.overrideValue("wot", null, null, "wot-null")
	}	
}

internal class T_MyModule30 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService19#).withId("s19")
	}
	@Contribute{ serviceId="s19" }
	static Void cont(Configuration config) {
		config.add("wot")
	}
	@Contribute{ serviceId="s19" }
	static Void cont2(Configuration config) {
		config.add("ever")
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
		binder.bind(T_MyService20#).withId("s20")
	}
	
	@Contribute{ serviceId="s20" }
	static Void cont(Configuration config) {
		config.add("wot")
	}
}

internal class T_MyService20 {
	new make(List config) { }
}

internal class T_MyModule32 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService02#).withId("s2")
	}
	
	@Build
	static T_MyService21 buildS21(Str[] str, T_MyService02 s2) {
		T_MyService21(str.add(s2.kick))
	}
	
	@Contribute{ serviceId="s21" }
	static Void cont(Configuration config) {
		config.add("wot")
	}
	@Contribute{ serviceId="s21" }
	static Void cont2(Configuration config) {
		config.add("ever")
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
		binder.bind(T_MyService02#).withId("s2")
		binder.bind(T_MyService21#).withId("s21")
	}
	
	@Contribute{ serviceId="s21" }
	static Void cont(Configuration config, T_MyService02 s2) {
		config.add("wot")
		config.add(s2.kick)
	}
}

internal class T_MyModule35 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService22#).withId("s22")
		binder.bind(T_MyService22#).withId("s22-b")
	}
	
	@Contribute{ serviceId="s22" }
	static Void cont(Configuration config) {
		config.add(T_MyModule35#)	// add fail, need an Int, not Type
	}
	@Contribute{ serviceId="s22-b" }
	static Void cont2(Configuration config) {
		config.add("69")	// gets coerced to Int
	}
}

internal class T_MyService22 {
	Int[] config
	new make(Int[] config) {
		this.config = config
	}
}

internal class T_MyModule36 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService23#).withId("s23")
	}
	
	@Contribute{ serviceId="s23" }
	static Void cont(Configuration config) {
		config.add(config.autobuild(T_MyService02#)->kick)
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
		binder.bind(T_MyService23#).withId("s23")
	}	
}

internal class T_MyModule69 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService23#).withId("s23")
	}
	@Contribute
	static Void contributeS23(Configuration config) {
		config["key"] = "value1"
		config.overrideValue("key", "value2", null, "over1")
	}
}

internal class T_MyModule70 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService23#).withId("s23")
	}
	@Contribute
	static Void contributeS23(Configuration config) {
		config["key"] = "value1"
		config.overrideValue("key", "value2", null, "over1")
		config.overrideValue("over1", "value3", null, "over2")
	}
}

internal class T_MyModule71 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService23#).withId("s23")
	}
	@Contribute
	static Void contributeS23(Configuration config) {
		config["key"] = "value"
		config.overrideValue("non-exist", "value2", null, "over1")
	}
}

internal class T_MyModule72 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService23#).withId("s23")
	}
	@Contribute
	static Void contributeS23(Configuration config) {
		config["key"] = "value"
		config.overrideValue("key", "value2", null, "over1")
		config.overrideValue("non-exist", "value3", null, "over2")
	}
}

internal class T_MyModule86 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService23#).withId("s23")
	}
	@Contribute
	static Void contributeS23(Configuration config) {		
		config.addPlaceholder("filters")
		config.addPlaceholder("routes")
		
		config.set("corsFilter", "simple", 	  "before: routes")
		config.set("corsFilter2", "preflight", "before: routes")

		// we would expect these to appear *after* the 2 filters above
//		config = ,["essays1", "essays2", "index";
		config.add("essays1")
		config.add("essays2")
		config.add("index")
	}
}

internal class T_MyModule89 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService73#).withId("s73")
	}
	@Contribute
	static Void contributeS73(Configuration config) {		
		config.add(1)
		config.add(2)
		config.add(3)
		config.add(4)
		config.add(5)
		config.add(6)
		config.add(7)
		config.add(8)
		config.add(9)
		config.add(10)
	}
}

internal class T_MyService73 {
	Int[] config
	new make(Int[] config) {
		this.config = config
	}
}

internal class T_MyService82 { 
	Str[]? filters
	new make(Str[] config) {
		this.filters = config
	}
}
internal class T_MyModule92 {
	
	@Contribute { serviceType=T_MyService82# }
	static Void contributeHttpPipeline1(Configuration config) {
		config.set("IeAjaxCacheBustingFilter", "IeAjaxCacheBustingFilter#", "after: BedSheetFilters")
	}

	@Contribute { serviceType=T_MyService82# }
	static Void contributeHttpPipeline2(Configuration conf) {
		conf.set("HttpCleanupFilter", 	"HttpCleanupFilter#", "before: BedSheetFilters, before: HttpErrFilter")
		conf.set("HttpErrFilter", 		"HttpErrFilter#", 	  "before: BedSheetFilters")		
		conf.addPlaceholder("BedSheetFilters")
	}

	@Build { serviceId="s82"; disableProxy=true }
	static T_MyService82 buildHttpPipeline(Str[] filters) {
		return T_MyService82(filters)
	}	
}

@SubModule { modules=[T_MyModule92#] }
internal class T_MyModule93 {
	@Contribute { serviceType=T_MyService82# }
	static Void contributeRemoval(Configuration config) {
		config.remove("HttpErrFilter", "gone")
	}
}

internal class T_MyModule94 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService82#).withId("s82")
	}	
	@Contribute { serviceType=T_MyService82# }
	static Void contribute(Configuration conf) {
		conf.set("A", "A", "before: C, before: B")
		conf.set("B", "B", "before: C")
		conf.addPlaceholder("C")	
		conf.overrideValue("B", "D", null, "D")
	}
}

