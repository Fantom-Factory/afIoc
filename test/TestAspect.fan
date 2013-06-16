
internal class TestAspect : IocTest {
	
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
		s65 := reg.dependencyByType(PublicTestTypes.type("T_MyService65Aspect"))
		s66 := reg.dependencyByType(PublicTestTypes.type("T_MyService66Aspect"))
		s67 := reg.dependencyByType(PublicTestTypes.type("T_MyService67NoMatch"))
		
		verifyEq(s65->meth1, "dredd MUTHA FUKIN ADVISED!")
		verifyEq(s66->meth2, "anderson MUTHA FUKIN ADVISED!")
		verifyEq(s67->meth3, "death")
	}

	Void testNestedAdvice() {
		reg := RegistryBuilder().addModule(T_MyModule81#).build.startup
		s65 := reg.dependencyByType(PublicTestTypes.type("T_MyService65Aspect"))
		s66 := reg.dependencyByType(PublicTestTypes.type("T_MyService66Aspect"))
		s67 := reg.dependencyByType(PublicTestTypes.type("T_MyService67NoMatch"))
		
		verifyEq(s65->meth1, "dredd add1 add2 add3")
		verifyEq(s66->meth2, "anderson add1 add2 add3")
		verifyEq(s67->meth3, "death")
	}
	
	Void testGlobMatching() {
		def := StandardAdviceDef {
			it.serviceIdGlob	= "*Aspect"
			it.advisorMethod	= Obj#hash
		}
		verify(def.matchesServiceId("T_MyService65Aspect"))
		verifyFalse(def.matchesServiceId("T_MyService67NoMatch"))
	}
	
	Void testAdvisingNonProxy() {
		verifyErrMsg(IocMessages.adviceDoesNotMatchAnyServices(StandardAdviceDef {
			it.advisorMethod = T_MyModule11#addTransactions
			it.serviceIdGlob = "s69"
		}, Str[,])) {
			reg := RegistryBuilder().addModule(T_MyModule11#).build.startup
		}
	}

	Void testAdvisingOptionalNonProxy() {
		reg := RegistryBuilder().addModule(T_MyModule84#).build.startup
		s69 := (T_MyService69) reg.serviceById("s69")
		verifyEq(s69.judge, "tell it to the")
	}
}

internal class T_MyModule78 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(PublicTestTypes.type("T_MyService65Aspect")).withId("s65Aspect")
		binder.bindImpl(PublicTestTypes.type("T_MyService66Aspect")).withId("s66Aspect")
		binder.bindImpl(PublicTestTypes.type("T_MyService67NoMatch")).withId("s67NoMatch")
	}
	
	@Advise { serviceId="*Aspect" }
	static Void addTransactions(MethodAdvisor[] methodAdvisors) {
		methodAdvisors.each |advisor| {
			advisor.addAdvice |invocation -> Obj?| {
				ret := (Str) invocation.invoke
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

internal class T_MyModule81 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(PublicTestTypes.type("T_MyService65Aspect")).withId("s65Aspect")
		binder.bindImpl(PublicTestTypes.type("T_MyService66Aspect")).withId("s66Aspect")
		binder.bindImpl(PublicTestTypes.type("T_MyService67NoMatch")).withId("s67NoMatch")
	}
	
	@Advise { serviceId="s??*As*" }
	static Void advise1(MethodAdvisor[] methodAdvisors) {
		methodAdvisors.each |advisor| {
			advisor.addAdvice |invocation -> Obj?| {
				ret := (Str) invocation.invoke
				return ret + " add1"
			}
		}
	}

	@Advise { serviceId="s??*As*" }
	static Void advise2(MethodAdvisor[] methodAdvisors) {
		methodAdvisors.each |advisor| {
			advisor.addAdvice |invocation -> Obj?| {
				ret := (Str) invocation.invoke
				return ret + " add2"
			}
		}
	}

	@Advise { serviceId="s??*As*" }
	static Void advise3(MethodAdvisor[] methodAdvisors) {
		methodAdvisors.each |advisor| {
			advisor.addAdvice |invocation -> Obj?| {
				ret := (Str) invocation.invoke
				return ret + " add3"
			}
		}
	}
}

internal class T_MyModule11 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService69#).withId("s69")
	}	
	@Advise { serviceId="s69" }
	static Void addTransactions(MethodAdvisor[] methodAdvisors) { }
}

internal class T_MyModule84 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService69#).withId("s69")
	}	
	@Advise { serviceId="s69"; optional=true }
	static Void addTransactions(MethodAdvisor[] methodAdvisors) { }
}

internal class T_MyService69 {
	Str judge() {
		"tell it to the"
	}
}
