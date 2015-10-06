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
		// we would normally use just root and thread scopes, but JS can't handle immutable funcs
		// so make 2 threaded scopes instead		
		reg := RegistryBuilder() {
			addScope("thread-1", true) 
			addScope("thread-2", true) 
			addService(T_MyService60#).withId("s60").withScope("thread-1")
			addService(T_MyService02#).withId("s02").withScope("thread-2")
		}.build

		reg.rootScope.createChildScope("thread-1") |threadScope| {			
			s60 := (T_MyService60) threadScope.serviceById("s60")
	
			verifyErrMsg(ServiceNotFoundErr#, ErrMsgs.scope_couldNotFindServiceByType(T_MyService02#, "builtIn root thread-1".split)) {
				s60.lazyFunc()
			}
	
			// --==%% -- FEEL THE POWER!!! -- %%==--
			threadScope.createChildScope("thread-2") {
				s02 := s60.lazyFunc()
				verifyType(s02, T_MyService02#)
			}
		}
	}

	// This tests the REAL POWER behind Factory Funcs - who needs proxies!?
	Void testFactoryFuncsUseActiveScope() {
		// we would normally use just root and thread scopes, but JS can't handle immutable funcs
		// so make 2 threaded scopes instead		
		reg := RegistryBuilder() {
			addScope("thread-1", true) 
			addScope("thread-2", true) 
			addService(T_MyService60#).withId("s60").withScope("thread-1")
			addService(T_MyService02#).withId("s02").withScope("thread-2")
		}.build
		
		reg.rootScope.createChildScope("thread-1") |threadScope| {			
			s60 := (T_MyService60) threadScope.serviceById("s60")
			
			verifyIocErrMsg(ErrMsgs.autobuilder_couldNotFindAutobuildCtor(T_MyService64#, [Str#])) {
				s60.factoryFunc("Dude!")
			}
	
			// --==%% -- FEEL THE POWER!!! -- %%==--
			reg.rootScope.createChildScope("thread-2") {
				s64 := (T_MyService64) s60.factoryFunc("Dude!")
				verifyEq(s64.str, "Dude!")
				verifyType(s64.s02, T_MyService02#)
			}
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
internal class T_MyService60 {
	@Inject |->T_MyService02| lazyFunc
	@Inject |Str->T_MyService64| factoryFunc
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
