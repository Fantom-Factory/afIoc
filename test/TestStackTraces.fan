
internal class TestStackTraces : IocTest {

	Void testRegistryBuild() {
		verifyReducedStack {
			RegistryBuilder().addModule(T_MyModule40#).build
		}
	}
	
	Void testDependencyByType() {
		reg := RegistryBuilder().addModule(T_MyModule01#).build.startup
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
		reg := RegistryBuilder().addModule(T_MyModule03#).build.startup
		verifyReducedStack {
			reg.injectIntoFields(T_MyService01())
		}
	}

	Void verifyReducedStack(|Obj| func) {
		try {
			func.call(69)
			fail
		} catch (IocErr e) {
			stack  := (Str[]) e.traceToStr.split('\n')
				.exclude { it.contains(TestStackTraces#.name) }
				.exclude { it.contains("fanx.tools.Fant") }
				.exclude { it.contains("fan.sys.Method") }
				.exclude { it.contains("Operations trace") }
				.exclude { it.contains("[ ") }
				.exclude { it.contains(Utils#stackTraceFilter.name) }
				.exclude { it.contains("Ioc Operation Trace:") }
				.exclude { it.contains("Stack Trace:") }
			verify(stack.size <= 5, stack.join("\n"))
		}
	}
}
