
internal class TestCreateProxy : IocTest {
	
	Void testCreateProxyThreaded() {
		reg := RegistryBuilder().build.startup
		s87 := (T_MyService87) reg.createProxy(T_MyService87#, T_MyService87Impl#, [69])
		
		verifyFalse(s87.typeof.fits(T_MyService87Impl#))
		verifyEq(s87.num, 69)
		verifyEq(s87.reg.typeof, RegistryImpl#)
	}

	Void testCreateProxyApp() {
		reg := RegistryBuilder().build.startup
		s88 := (T_MyService88) reg.createProxy(T_MyService88#, T_MyService88Impl#, [69])
		
		verifyFalse(s88.typeof.fits(T_MyService88Impl#))
		verifyEq(s88.num, 69)
		verifyEq(s88.reg.typeof, RegistryImpl#)
	}
}

@NoDoc
mixin T_MyService87 {
	abstract Int num
	abstract Registry reg()
}

@NoDoc
class T_MyService87Impl : T_MyService87 {
	override Int num
	override Registry reg
	new make(Int num, Registry reg) {
		this.num = num
		this.reg = reg
	}
}

@NoDoc
const mixin T_MyService88 {
	abstract Int num()
	abstract Registry reg()
}

@NoDoc
const class T_MyService88Impl : T_MyService88 {
	override const Int num
	override const Registry reg
	new make(Int num, Registry reg) {
		this.num = num
		this.reg = reg
	}
}
