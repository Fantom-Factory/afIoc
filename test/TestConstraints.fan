
@Js
internal class TestConstraints : IocTest {
	
	Void testOptionalConstraints() {		
		// just ensure that the undefined optional contrib doesn't cause an error 
		threadScope { 
			addService(T_MyService82#)
			contributeToServiceType(T_MyService82#) |Configuration config| {
				config.add("MyContrib").after("something.else", true)
			}
		}.serviceByType(T_MyService82#)
	}

	Void testOrderGroups() {
		// mix up some contributions 
		s82 := (T_MyService12) threadScope { 
			addService(T_MyService12#)
			contributeToServiceType(T_MyService12#) |Configuration config| {
				config.inOrder { 
					config["a-1"] = 1
					config["a-2"] = 1
					config["a-3"] = 1
				}.after("afIoc.unordered- 2")
			}
			contributeToServiceType(T_MyService12#) |Configuration config| {
				config.inOrder { 
					config["b-1"] = 1
					config["b-2"] = 1
					config["b-3"] = 1
				}.after("a-2").after("afIoc.unordered- 2")
			}
			contributeToServiceType(T_MyService12#) |Configuration config| {
				config.inOrder { 
					config.add("c-1")
					config.add("c-2")
					config.add("c-3")
				}.before("a-2")
			}
			contributeToServiceType(T_MyService12#) |Configuration config| {
					config.set("d-1", 1).before("a-1")
					config.set("d-2", 1).before("b-1")
					config.set("d-3", 1).before("afIoc.unordered- 1").before("a-1")
			}
		}.serviceByType(T_MyService12#)
		
		verifyEq(s82.config.keys, "d-3, afIoc.unordered- 1, afIoc.unordered- 2, d-1, a-1, afIoc.unordered- 3, a-2, a-3, d-2, b-1, b-2, b-3".split(','))		
	}

}

@Js
internal class T_MyService12 { 
	Str:Obj config
	new make(Str:Obj config) {
		this.config = config
	}
}