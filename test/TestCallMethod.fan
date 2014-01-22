
internal class TestCallMethod : IocTest {

	Int? num
	Type? type
	Str? wot
	
	override Void setup() {
		num = null
		type = null
		wot = null
	}
	
	Void testCallMethod() {
		reg := RegistryBuilder().build.startup
		reg.callMethod(#callMe, this, [69])
		verifyEq(num, 69)
		verifyEq(type, RegistryImpl#)
	}

	Void testCallMethodDefaultNull() {
		reg := RegistryBuilder().build.startup
		
		reg.callMethod(#callMeDefaultNull, this, [69])
		verifyEq(num, 69)
		verifyEq(type, RegistryImpl#)
		verifyEq(wot, null)

		reg.callMethod(#callMeDefaultNull, this, [69, reg, "judge"])
		verifyEq(num, 69)
		verifyEq(type, RegistryImpl#)
		verifyEq(wot, "judge")
	}

	Void testCallMethodDefaultVal() {
		reg := RegistryBuilder().build.startup
		
		reg.callMethod(#callMeDefaultVal, this, [69])
		verifyEq(num, 69)
		verifyEq(type, RegistryImpl#)
		verifyEq(wot, "dude")

		reg.callMethod(#callMeDefaultVal, this, [69, reg, "judge"])
		verifyEq(num, 69)
		verifyEq(type, RegistryImpl#)
		verifyEq(wot, "judge")

		// check default params are still injected
		wot = null
		reg.callMethod(#callMeDefaultIoc, this, [69])
		verifyEq(num, 69)
		verifyEq(type, RegistryImpl#)
		verifyEq(wot, null)
	}

	Void testErrsAreUnwrapped() {
		verifyErrMsgAndType(ArgErr#, "Poo") {
			throw ArgErr("Poo")
		}
	}
	
	Void callMe(Int num, Registry registry) {
		this.num = num
		this.type = registry.typeof
	}
	Void callMeDefaultNull(Int num, Registry registry, Str? wot := null) {
		this.num = num
		this.type = registry.typeof
		this.wot = wot
	}
	Void callMeDefaultVal(Int num, Registry registry, Str? wot := "dude") {
		this.num = num
		this.type = registry.typeof
		this.wot = wot
	}
	Void callMeDefaultIoc(Int num, Registry? registry := null) {
		this.num = num
		this.type = registry.typeof
	}
}

