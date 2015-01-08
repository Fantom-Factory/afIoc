
internal class TestAspect : IocTest {
	
	Void testContributionMethodMustBeStatic() {
		verifyIocErrMsg(IocMessages.adviseMethodMustBeStatic(T_MyModule79#adviseStuff)) {
			RegistryBuilder().addModule(T_MyModule79#).build.startup
		}  
	}

	Void testContributionMethodMustTakeConfig() {
		verifyIocErrMsg(IocMessages.adviseMethodMustTakeMethodAdvisorList(T_MyModule80#adviseStuff)) {
			RegistryBuilder().addModule(T_MyModule80#).build.startup
		}  
	}
	
	Void testAdvice() {
		reg := RegistryBuilder().addModule(T_MyModule78#).build.startup
		s65 := reg.dependencyByType(T_MyService65Aspect#)
		s66 := reg.dependencyByType(T_MyService66Aspect#)
		s67 := reg.dependencyByType(T_MyService67NoMatch#)
		
		verifyEq(s65->meth1, "dredd MUTHA FUKIN ADVISED!")
		verifyEq(s66->meth2, "anderson MUTHA FUKIN ADVISED!")
		verifyEq(s67->meth3, "death")
	}

	Void testNestedAdvice() {
		reg := RegistryBuilder().addModule(T_MyModule81#).build.startup
		s65 := reg.dependencyByType(T_MyService65Aspect#)
		s66 := reg.dependencyByType(T_MyService66Aspect#)
		s67 := reg.dependencyByType(T_MyService67NoMatch#)
		
		verifyEq(s65->meth1, "dredd add1 add2 add3")
		verifyEq(s66->meth2, "anderson add1 add2 add3")
		verifyEq(s67->meth3, "death")
	}
	
	Void testGlobMatching() {
		def := AdviceDef {
			it.serviceIdGlob	= "*Aspect"
			it.advisorMethod	= Obj#hash
		}

		serviceDef := ServiceDef(null) {
			it.serviceId 		= "T_MyService65Aspect"
			it.serviceType 		= Type#
			it.serviceProxy		= ServiceProxy.always
			it.serviceScope		= it.serviceType.isConst ? ServiceScope.perApplication : ServiceScope.perThread
			it.description 		= ""
			it.serviceBuilder	= |->Obj| { 6 }
		}
		verify(def.matchesService(serviceDef))
		
		serviceDef = ServiceDef(null) {
			it.serviceId 		= "T_MyService67NoMatch"
			it.serviceType 		= Type#
			it.serviceScope		= it.serviceType.isConst ? ServiceScope.perApplication : ServiceScope.perThread
			it.serviceProxy		= ServiceProxy.always
			it.description 		= ""
			it.serviceBuilder	= |->Obj| { 9 }
		}		
		verifyFalse(def.matchesService(serviceDef))
	}
	
	Void testAdvisingNonProxy() {
		verifySrvNotFoundErrMsg(IocMessages.adviceDoesNotMatchAnyServices(AdviceDef {
			it.advisorMethod = T_MyModule11#addTransactions
			it.serviceIdGlob = "s69"
		})) {
			RegistryBuilder().addModule(T_MyModule11#).build.startup
		}
	}

	Void testAdvisingOptionalNonProxy() {
		reg := RegistryBuilder().addModule(T_MyModule84#).build.startup
		s69 := (T_MyService69) reg.serviceById("s69-bingo")
		verifyEq(s69.judge, "tell it to the")
	}

	Void testAdvisingByServiceType() {
		reg := RegistryBuilder().addModule(T_MyModule81#).build.startup
		s60 := (T_MyService60) reg.serviceById("s60")
		verifyEq(s60.meth1, "dredd advised")
	}
}

internal class T_MyModule78 {
	static Void defineServices(ServiceDefinitions defs) {
		defs.add(T_MyService65Aspect#).withId("s65Aspect")
		defs.add(T_MyService66Aspect#).withId("s66Aspect")
		defs.add(T_MyService67NoMatch#).withId("s67NoMatch")
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
	static Void defineServices(ServiceDefinitions defs) {
		defs.add(T_MyService65Aspect#).withId("s65Aspect")
		defs.add(T_MyService66Aspect#).withId("s66Aspect")
		defs.add(T_MyService67NoMatch#).withId("s67NoMatch")
		defs.add(T_MyService60#).withId("s60")
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

	@Advise { serviceType=T_MyService60# }
	static Void adviseByType(MethodAdvisor[] methodAdvisors) {
		methodAdvisors.each |advisor| {
			advisor.addAdvice |invocation -> Obj?| {
				ret := (Str) invocation.invoke
				return ret + " advised"
			}
		}
	}
}

internal class T_MyModule11 {
	static Void defineServices(ServiceDefinitions defs) {
		defs.add(T_MyService69#).withId("s69-bingo")
	}	
	@Advise { serviceId="s69" }
	static Void addTransactions(MethodAdvisor[] methodAdvisors) { }
}

internal class T_MyModule84 {
	static Void defineServices(ServiceDefinitions defs) {
		defs.add(T_MyService69#).withId("s69-bingo")
	}	
	@Advise { serviceId="s69"; optional=true }
	static Void addTransactions(MethodAdvisor[] methodAdvisors) { }
}

internal class T_MyService69 {
	Str judge() {
		"tell it to the"
	}
}

@NoDoc mixin T_MyService60 {
	abstract Str meth1()
}
@NoDoc class T_MyService60Impl : T_MyService60 {
	override Str meth1() { "dredd" }
}
@NoDoc mixin T_MyService65Aspect {
	abstract Str meth1()
}
@NoDoc class T_MyService65AspectImpl : T_MyService65Aspect {
	override Str meth1() { "dredd" }
}
@NoDoc mixin T_MyService66Aspect {
	abstract Str meth2()
}
@NoDoc class T_MyService66AspectImpl : T_MyService66Aspect {
	override Str meth2() { "anderson" }
}
@NoDoc mixin T_MyService67NoMatch {
	abstract Str meth3()
}
@NoDoc class T_MyService67NoMatchImpl : T_MyService67NoMatch {
	override Str meth3() { "death" }
}
