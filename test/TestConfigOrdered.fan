
@Js
internal class TestConfigOrdered : IocTest {
	
	Void testErrIfConfigIsGeneric() {
		scope := threadScope { addModule(T_MyModule31#) }
		verifyIocErrMsg(ErrMsgs.contributions_configTypeIsGeneric(List#, "s20")) {
			scope.serviceById("s20")
		}
	}

	Void testBasicConfig() {
		reg := threadScope { addModule(T_MyModule30#) }
		s19 := reg.serviceById("s19") as T_MyService19
		verifyEq(s19.config, Str["wot", "ever"])
	}

	Void testBasicConfigViaBuilder() {
		reg := threadScope { addModule(T_MyModule32#) }
		s21 := reg.serviceById("s21") as T_MyService21
		verifyEq(s21.config, Str["wot", "ever", "ASS!"])
	}

	Void testConfigMethodInjection() {
		reg := threadScope { addModule(T_MyModule33#) }
		s21 := reg.serviceById("s21") as T_MyService21
		verifyEq(s21.config, Str["wot", "ASS!"])
	}

	Void testAddingWrongContrib() {
		reg := threadScope { addModule(T_MyModule35#) }
		verifyIocErrMsg(ErrMsgs.contributions_configTypeMismatch("value", Type#, Int#)) {
			s22 := reg.serviceById("s22") as T_MyService22
		}
	}

	Void testContribIsCoerced() {
		reg := threadScope { addModule(T_MyModule35#) }
		s22 := reg.serviceById("s22-b") as T_MyService22
		verifyEq(s22.config[0], 69)
	}
	
	Void testOrderedConfigAutobuild() {
		reg := threadScope { addModule(T_MyModule36#) }
		s23 := reg.serviceById("s23") as T_MyService23
		verifyEq(s23.config, Str["ASS!"])
	}

	Void testEmptyListCreatedWhenNoContribsFound() {
		reg := threadScope { addModule(T_MyModule38#) }
		s23 := reg.serviceById("s23") as T_MyService23
		verifyEq(s23.config, Str[,])
	}

	Void testPlaceholderOrder() {
		reg := threadScope { addModule(T_MyModule86#) }
		s23 := reg.serviceById("s23") as T_MyService23
		
		verifyEq(s23.config[0], "simple")
		verifyEq(s23.config[1], "preflight")
		verifyEq(s23.config[2], "essays1")
		verifyEq(s23.config[3], "essays2")
		verifyEq(s23.config[4], "index")
	}

	// ---- test overrides ------------------------------------------------------------------------
	
	Void testOverride1() {
		reg := threadScope { addModule(T_MyModule69#) }
		s23 := reg.serviceById("s23") as T_MyService23
		verifyEq(s23.config.size, 1)
		verifyEq(s23.config[0], "value2")
	}

	Void testOverride2() {
		reg := threadScope { addModule(T_MyModule70#) }
		s23 := reg.serviceById("s23") as T_MyService23
		verifyEq(s23.config.size, 1)
		verifyEq(s23.config[0], "value3")
	}

	Void testOverrideMustExist1() {
		reg := threadScope { addModule(T_MyModule71#) }
		verifyIocErrMsg(ErrMsgs.contributions_overrideDoesNotExist("non-exist", "over1")) {
			reg.serviceById("s23")
		}
	}

	Void testOverrideMustExist2() {
		reg := threadScope { addModule(T_MyModule72#) }
		verifyIocErrMsg(ErrMsgs.contributions_overrideDoesNotExist("non-exist", "over2")) {
			reg.serviceById("s23")
		}
	}
	
	// ---- test null values ----------------------------------------------------------------------

	Void testNullValue() {
		reg := threadScope { addModule(T_MyModule87#) }
		s71 := (T_MyService71) reg.serviceById("s71")
		verifyEq(s71.config.size, 1)
		verifyEq(s71.config[0], null)		
	}

	Void testNullValueNotAllowed() {
		reg := threadScope { addModule(T_MyModule87#) }
		verifyIocErrMsg(ErrMsgs.contributions_configTypeMismatch("value", null, Str#)) {
			s19 := (T_MyService28) reg.serviceById("s19")
		}
	}

	Void testCanOverrideWithNull() {
		reg := threadScope { addModule(T_MyModule87#) }
		s71 := (T_MyService71) reg.serviceById("s71")
		verifyEq(s71.config.size, 1)
		verifyEq(s71.config[0], null)		
	}	

	// ---- test null values ----------------------------------------------------------------------

	Void testUnorderedIsOrdered() {
		reg := threadScope { addModule(T_MyModule89#) }
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
	
	Void testDagBug() {
		reg := threadScope { 
			it.addService(T_MyService82#).withId("s82")
			it.contributeToServiceType(T_MyService82#) |Configuration config| {
				config.set("ajax",  "Ajax#").after("BedSheet")
				config.set("Clean", "Clean#").before("BedSheet").before("Err")
				config.set("Err", 	"Err#"	).before("BedSheet")		
				config.addPlaceholder("BedSheet")				
			}
		}
		s82 := (T_MyService82) reg.serviceById("s82")
		
		verifyEq(s82.filters, ["Clean#", "Err#", "Ajax#"])
	}

	Void testFilterBug() {
		reg := threadScope { addModule(T_MyModule92#) }
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
		reg := threadScope { addModule(T_MyModule94#) }
		s82 := (T_MyService82) reg.serviceById("s82")
		
		verifyEq(s82.filters.size, 2)
		verifyEq(s82.filters[0], "A")
		verifyEq(s82.filters[1], "D")		
	}

	// ---- Remove Tests --------------------------------------------------------------------------

	Void testRemove() {
		reg := threadScope { addModule(T_MyModule93#) }
		s82 := (T_MyService82) reg.serviceById("s82")
		
		verifyEq(s82.filters.size, 2)
		verifyEq(s82.filters[0], "HttpCleanupFilter#")
		verifyEq(s82.filters[1], "IeAjaxCacheBustingFilter#")		
	}
}

@Js
internal class T_MyService71 {
	Str?[] config
	new make(Str?[] config) {
		this.config = config
	}
}

@Js
internal const class T_MyModule87 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService71#).withId("s71")
		defs.addService(T_MyService19#).withId("s19")
		defs.addService(T_MyService71#).withId("s71b")
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
		config.overrideValue("wot", null, "wot-null")
	}	
}

@Js
internal const class T_MyModule30 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService19#).withId("s19")
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

@Js
internal class T_MyService19 {
	Str[] config
	new make(Str[] config) {
		this.config = config
	}
}

@Js
internal const class T_MyModule31 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService20#).withId("s20")
	}
	
	@Contribute{ serviceId="s20" }
	static Void cont(Configuration config) {
		config.add("wot")
	}
}

@Js
internal class T_MyService20 {
	new make(List config) { }
}

@Js
internal const class T_MyModule32 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService02#).withId("s2")
	}
	
	@Build { serviceId = "s21" }
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

@Js
internal class T_MyService21 {
	Str[] config
	new make(Str[] config) {
		this.config = config
	}
}

@Js
internal const class T_MyModule33 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService02#).withId("s2")
		defs.addService(T_MyService21#).withId("s21")
	}
	
	@Contribute{ serviceId="s21" }
	static Void cont(Configuration config, T_MyService02 s2) {
		config.add("wot")
		config.add(s2.kick)
	}
}

@Js
internal const class T_MyModule35 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService22#).withId("s22")
		defs.addService(T_MyService22#).withId("s22-b")
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

@Js
internal class T_MyService22 {
	Int[] config
	new make(Int[] config) {
		this.config = config
	}
}

@Js
internal const class T_MyModule36 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService23#).withId("s23")
	}
	
	@Contribute{ serviceId="s23" }
	static Void cont(Configuration config) {
		config.add(config.build(T_MyService02#)->kick)
	}
}

@Js
internal class T_MyService23 {
	Str[] config
	new make(Str[] config) {
		this.config = config
	}
}

@Js
internal const class T_MyModule38 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService23#).withId("s23")
	}	
}

@Js
internal const class T_MyModule69 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService23#).withId("s23")
	}
	@Contribute { serviceId="s23" }
	static Void contributeS23(Configuration config) {
		config["key"] = "value1"
		config.overrideValue("key", "value2", "over1")
	}
}

@Js
internal const class T_MyModule70 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService23#).withId("s23")
	}
	@Contribute { serviceId="s23" }
	static Void contributeS23(Configuration config) {
		config["key"] = "value1"
		config.overrideValue("key", "value2", "over1")
		config.overrideValue("over1", "value3", "over2")
	}
}

@Js
internal const class T_MyModule71 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService23#).withId("s23")
	}
	@Contribute { serviceId="s23" }
	static Void contributeS23(Configuration config) {
		config["key"] = "value"
		config.overrideValue("non-exist", "value2", "over1")
	}
}

@Js
internal const class T_MyModule72 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService23#).withId("s23")
	}
	@Contribute { serviceId="s23" }
	static Void contributeS23(Configuration config) {
		config["key"] = "value"
		config.overrideValue("key", "value2", "over1")
		config.overrideValue("non-exist", "value3", "over2")
	}
}

@Js
internal const class T_MyModule86 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService23#).withId("s23")
	}
	@Contribute { serviceId="s23" }
	static Void contributeS23(Configuration config) {		
		config.addPlaceholder("filters")
		config.addPlaceholder("routes")
		
		config.set("corsFilter", "simple").before("routes")
		config.set("corsFilter2", "preflight").before("routes")

		// we would expect these to appear *after* the 2 filters above
//		config = ,["essays1", "essays2", "index";
		config.add("essays1")
		config.add("essays2")
		config.add("index")
	}
}

@Js
internal const class T_MyModule89 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService73#).withId("s73")
	}
	@Contribute { serviceId="s73" }
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

@Js
internal class T_MyService73 {
	Int[] config
	new make(Int[] config) {
		this.config = config
	}
}

@Js
internal class T_MyService82 { 
	Str[]? filters
	new make(Str[] config) {
		this.filters = config
	}
}
@Js
internal const class T_MyModule92 {
	
	@Contribute { serviceType=T_MyService82# }
	static Void contributeHttpPipeline1(Configuration config) {
		config.set("IeAjaxCacheBustingFilter", "IeAjaxCacheBustingFilter#").after("BedSheetFilters")
	}

	@Contribute { serviceType=T_MyService82# }
	static Void contributeHttpPipeline2(Configuration conf) {
		conf.set("HttpCleanupFilter", 	"HttpCleanupFilter#").before("BedSheetFilters").before("HttpErrFilter")
		conf.set("HttpErrFilter", 		"HttpErrFilter#"	).before("BedSheetFilters")		
		conf.addPlaceholder("BedSheetFilters")
	}

	@Build { serviceId="s82" }
	static T_MyService82 buildHttpPipeline(Str[] filters) {
		return T_MyService82(filters)
	}	
}

@Js
@SubModule { modules=[T_MyModule92#] }
internal const class T_MyModule93 {
	@Contribute { serviceType=T_MyService82# }
	static Void contributeRemoval(Configuration config) {
		config.remove("HttpErrFilter", "gone")
	}
}

@Js
internal const class T_MyModule94 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService82#).withId("s82")
	}	
	@Contribute { serviceType=T_MyService82# }
	static Void contribute(Configuration conf) {
		conf.set("A", "A").before("C").before("B")
		conf.set("B", "B").before("C")
		conf.addPlaceholder("C")	
		conf.overrideValue("B", "D", "D")
	}
}

