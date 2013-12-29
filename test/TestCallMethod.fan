
internal class TestCallMethod : IocTest {

	Int? num
	Type? type
	
	Void testCallMethod() {
		reg := RegistryBuilder().build.startup
		reg.callMethod(#callMe, this, [69])
		verifyEq(num, 69)
		verifyEq(type, RegistryImpl#)
	}

	Void callMe(Int num, Registry registry) {
		this.num = num
		this.type = registry.typeof
	}
}

