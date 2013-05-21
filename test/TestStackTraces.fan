
class TestStackTraces : Test {

	Void testRegistryBuild() {
		verifyReducedStack {
			RegistryBuilder().addModule(T_MyModule40#).build
		}
	}

	Void testServiceById() {
		reg := RegistryBuilder().addModule(T_MyModule1#).build.startup
		verifyReducedStack {
			reg.serviceById("s1")
		}
	}

	Void testDependencyByType() {
		reg := RegistryBuilder().addModule(T_MyModule1#).build.startup
		verifyReducedStack {
			reg.dependencyByType(Int#)
		}
	}

	Void testAutobuild() {
		reg := RegistryBuilder().addModule(T_MyModule75#).build.startup
		verifyReducedStack {			
			reg.autobuild(T_MyService47#, ["Oops!"])
		}
	}
	
	Void testInjectIntoFields() {
		reg := RegistryBuilder().addModule(T_MyModule3#).build.startup
		verifyReducedStack {
			reg.injectIntoFields(T_MyService1())
		}
	}
	
	Void verifyReducedStack(|Obj| func) {
		try {
			func.call(69)
			fail
		} catch (IocErr e) {
			stack  := (Str[]) e.traceToStr.split('\n').exclude { it.contains(TestStackTraces#.name) }.exclude { it.contains("fanx.tools.Fant") }.exclude { it.contains("fan.sys.Method") }
			verify(stack.size <= 5, stack.join("\n"))
		}
	}
}
