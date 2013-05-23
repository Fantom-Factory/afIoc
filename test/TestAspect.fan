
class TestAspect : IocTest {
	
	Void testContributionMethodMustBeStatic() {
		verifyErrMsg(IocMessages.adviseMethodMustBeStatic(T_MyModule79#adviseStuff)) {
			RegistryBuilder().addModule(T_MyModule79#).build.startup
		}  
	}

	Void testContributionMethodMustTakeConfig() {
		verifyErrMsg(IocMessages.adviseMethodMustTakeMethodAdvisorList(T_MyModule80#adviseStuff)) {
			RegistryBuilder().addModule(T_MyModule80#).build.startup
		}  
	}
	
	Void testAdvice() {
		reg := RegistryBuilder().addModule(T_MyModule78#).build.startup
		s65 := reg.dependencyByType(T_MyService65Aspect#) as T_MyService65Aspect
		s66 := reg.dependencyByType(T_MyService66Aspect#) as T_MyService66Aspect
		s67 := reg.dependencyByType(T_MyService67NoMatch#) as T_MyService67NoMatch
		
		verifyEq(s65.meth1, "dredd MUTHA FUKIN ADVISED!")
		verifyEq(s66.meth2, "anderson MUTHA FUKIN ADVISED!")
		verifyEq(s67.meth3, "death")
	}

	Void testGlobMatching() {
		def := StandardAdviceDef {
			it.serviceIdGlob	= "*Aspect"
			it.advisorMethod	= Obj#hash
		}
		verify(def.matchesServiceId("T_MyService65Aspect"))
		verifyFalse(def.matchesServiceId("T_MyService67NoMatch"))
	}
}

internal class T_MyModule78 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService65Aspect#).withId("s65Aspect")
		binder.bindImpl(T_MyService66Aspect#).withId("s66Aspect")
		binder.bindImpl(T_MyService67NoMatch#).withId("s67NoMatch")
	}
	
	@Advise { serviceId="*Aspect" }
	static Void addTransactions(MethodAdvisor[] methodAdvisors) {
		methodAdvisors.each |advisor| {
			advisor.addAdvice |target, args -> Obj?| {
				Env.cur.err.printLine("ADISNLKSNDL")
				ret := (Str) advisor.method.callOn(target, args)
				return ret + " MUTHA FUKIN ADVISED!"
			}
		}
	}
}

internal class T_MyModule79 {
	@Advise { serviceId="*Aspect" }
	Void adviseStuff(MethodAdvisor[] methodAdvisors) { }
}

internal class T_MyModule80 {
	@Advise { serviceId="*Aspect" }
	static Void adviseStuff(Int wotever, MethodAdvisor[] methodAdvisors) { }
}



mixin T_MyService65Aspect {
	abstract Str meth1()
}
class T_MyService65AspectImpl : T_MyService65Aspect {
	override Str meth1() { "dredd" }
}
mixin T_MyService66Aspect {
	abstract Str meth2()
}
class T_MyService66AspectImpl : T_MyService66Aspect {
	override Str meth2() { "anderson" }
}
mixin T_MyService67NoMatch {
	abstract Str meth3()
}
class T_MyService67NoMatchImpl : T_MyService67NoMatch {
	override Str meth3() { "death" }
}


