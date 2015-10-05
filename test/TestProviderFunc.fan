using concurrent

@Js
internal class TestProviderFunc : IocTest {

	Void testLazyFactory() {
		reg := threadScope { addService(T_MyService49#) }
		ser := (T_MyService49) reg.serviceByType(T_MyService49#)
		reg2:= ser.func()
		verifySame(reg.registry, reg2->registry)
	}

	Void testLazyFactoryByType() {
		reg := threadScope { addService(T_MyService57#) }
		ser := (T_MyService57) reg.serviceByType(T_MyService57#)
		reg2:= ser.func()
		verifySame(reg.registry, reg2->registry)
	}
	
	Void testLazyFuncsWithId() {
		verifyErrMsg(ServiceNotFoundErr#, ErrMsgs.funcProvider_couldNotFindService("Ooops")) {
			rootScope.build(T_MyService67#)
		}
	}

	Void testLazyFuncsMustHaveNoArgs() {
		verifyIocErrMsg(ErrMsgs.funcProvider_mustNotHaveArgs(|Str?->Registry|?#)) {
			rootScope.build(T_MyService52#)
			rootScope.serviceByType(|Str?->Registry|#)
		}
	}

	Void testFactoryFunc() {
		ser := (T_MyService50) rootScope.build(T_MyService50#)
		srv := ser.func()
		verifyEq(srv.str1, "none")
		verifyEq(srv.str2, "none")
	}

	Void testFactoryFuncWithArgs() {
		ser := (T_MyService51) rootScope.build(T_MyService51#)
		srv := ser.func("Judge", 69)
		verifyEq(srv.str1, "Judge")
		verifyEq(srv.str2, "69")
	}

	Void testFactoryFuncsAreImmutable() {
		// JS funcs can't be immutable
		if (Env.cur.runtime == "js") return

		scope := rootScope { addService(T_MyService110#) { withId("s110") } }
		s110 := (T_MyService110) scope.serviceById("s110")
		
		funcy1 := s110.funcy("Dredd", 8) 
		funcy2 := s110.funcy("Dredd", 8) 
		verifyEq(funcy1.str1, "Dredd")
		verifyEq(funcy2.str2, "8")
		verifyNotSame(funcy1, funcy2)
	}
	
	// This tests the REAL POWER behind Lazy Funcs - who needs proxies!?
	Void testLazyFuncsUseActiveScope() {
		reg := RegistryBuilder() {
			addScope("thread", true) 
			addService(T_MyService60#).withId("s60").withScope("root")
			addService(T_MyService02#).withId("s02").withScope("thread")
		}.build
		
		s60 := (T_MyService60) reg.rootScope.serviceById("s60")
		
		verifyErrMsg(ServiceNotFoundErr#, ErrMsgs.scope_couldNotFindServiceByType(T_MyService02#, "builtIn root".split)) {
			s60.lazyFunc()
		}

		// --==%% -- FEEL THE POWER!!! -- %%==--
		reg.rootScope.createChildScope("thread") {
			s02 := s60.lazyFunc()
			verifyType(s02, T_MyService02#)
		}
	}

	// This tests the REAL POWER behind Factory Funcs - who needs proxies!?
	Void testFactoryFuncsUseActiveScope() {
		reg := RegistryBuilder() {
			addScope("thread", true) 
			addService(T_MyService60#).withId("s60").withScope("root")
			addService(T_MyService02#).withId("s02").withScope("thread")
		}.build
		
		s60 := (T_MyService60) reg.rootScope.serviceById("s60")
		
		verifyIocErrMsg(ErrMsgs.autobuilder_couldNotFindAutobuildCtor(T_MyService64#, [Str#])) {
			s60.factoryFunc("Dude!")
		}

		// --==%% -- FEEL THE POWER!!! -- %%==--
		reg.rootScope.createChildScope("thread") {
			s64 := (T_MyService64) s60.factoryFunc("Dude!")
			verifyEq(s64.str, "Dude!")
			verifyType(s64.s02, T_MyService02#)
		}
	}
}

@Js
internal class T_MyService49 {
	@Inject |->Scope|? func
}

@Js
internal class T_MyService57 {
	@Inject { type=Scope# } 
	|->Obj|? func
}

@Js
internal class T_MyService50 {
	@Inject |->T_MyService109|? func
}

@Js
internal class T_MyService51 {
	@Inject |Str, Int->T_MyService109|? func
}

@Js
internal class T_MyService52 {
	@Inject |Str?->Registry|? func
}

@Js
internal const class T_MyService60 {
	@Inject const |->T_MyService02| lazyFunc
	@Inject const |Str->T_MyService64| factoryFunc
	new make(|This|in) { in(this) }
}

@Js
internal class T_MyService64 {
	Str str
	T_MyService02 s02
	new make(Str str, T_MyService02 s02) { this.str = str; this.s02 = s02 }
}

@Js
internal class T_MyService109 {
	Str str1	:= "none"
	Str str2	:= "none"
	new make1() {}
	new make2(Str s1, Int i2) {
		str1 = s1
		str2 = i2.toStr
	}
}

@Js
internal const class T_MyService110 {
	@Inject const |Str, Int->T_MyService109| funcy
	new make(|This|f) { f(this) }
}

@Js
internal class T_MyService67 {
	@Inject { id="Ooops" } 
	|->Scope|? func
}
