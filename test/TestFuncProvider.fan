using concurrent
using afConcurrent

internal class TestFactoryFuncProvider : IocTest {

	Void testLazyFactory() {
		reg := RegistryBuilder().build.startup
		
		func := (|->Registry|) reg.dependencyByType(|->Registry|#)
		reg2 := func()
		verifySame(reg, reg2)
	}
	
	Void testLazyFuncsMustHaveNoArgs() {
		reg := RegistryBuilder().build.startup
		verifyIocErrMsg(IocMessages.funcProvider_mustNotHaveArgs(|Str?->Registry|#)) {
			reg.dependencyByType(|Str?->Registry|#)
		}
	}

	Void testFactoryFunc() {
		reg := RegistryBuilder().build.startup
		
		func := (|->T_MyService109|) reg.dependencyByType(|->T_MyService109|#)
		srv  := func()
		verifyEq(srv.str1, "none")
		verifyEq(srv.str2, "none")
	}

	Void testFactoryFuncWithArgs() {
		reg := RegistryBuilder().build.startup
		
		func := (|Str, Int->T_MyService109|) reg.dependencyByType(|Str, Int->T_MyService109|#)
		srv  := func("Judge", 69)
		verifyEq(srv.str1, "Judge")
		verifyEq(srv.str2, "69")
		
	}
}

internal class T_MyService109 {
	Str str1	:= "none"
	Str str2	:= "none"
	new make1() {}
	new make2(Str s1, Int i2) {
		str1 = s1
		str2 = i2.toStr
	}
}
