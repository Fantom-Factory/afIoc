
class TestOrderedConfig : IocTest {
	
	Void testConfig() {
		Utils.setLoglevelDebug
		reg := RegistryBuilder().addModule(T_MyModule30#).build.startup
		s19 := reg.serviceById("s19") as T_MyService19
		verifyEq(s19.config, Str["ever", "wot"])
	}

	Void testErrIfConfigIsGeneric() {
		reg := RegistryBuilder().addModule(T_MyModule31#).build.startup
		verifyErrMsg(IocMessages.orderedConfigTypeIsGeneric(List#, "s20")) {
			reg.serviceById("s20")
		}
	}
}



internal class T_MyModule30 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService19#).withId("s19")
	}
	
	@Contribute{ serviceId="s19" }
	static Void cont(OrderedConfig config) {
		config.add("wot", "wot")
	}
	@Contribute{ serviceId="s19" }
	static Void cont2(OrderedConfig config) {
		config.add("ever", "ever", ["AFTER : wot"])
	}
}

internal class T_MyModule31 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService20#).withId("s20")
	}
	
	@Contribute{ serviceId="s20" }
	static Void cont(OrderedConfig config) {
		config.add("wot", "wot")
	}
}

internal class T_MyService19 {
	Str[] config
	new make(Str[] config) {
		this.config = config
	}
}

internal class T_MyService20 {
	new make(List config) { }
}