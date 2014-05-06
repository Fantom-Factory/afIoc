
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

	Void testLists() {
		reg := RegistryBuilder().build.startup
		reg.callMethod(#callMeList, this, [69, Str["Dude"]])
		verifyEq(num, 69)
		verifyEq(wot, "[Dude]")

		verifyErrMsg(IocMessages.providerMethodArgDoesNotFit(Int[]#, Str[]#)) {
			reg.callMethod(#callMeList2, this, [Int[69]])
		}
	}

	Void testLenientLists() {
		reg := RegistryBuilder().build.startup
		
		// ensure shorthand notation for empty lists still make it through
		reg.callMethod(#callMeList2, this, [ [,] ])
		verifyEq(wot, "[,]")

		// test type inference - if it *could* fit, it's allowed
		reg.callMethod(#callMeList2, this, [ Obj["Str!"] ])
		verifyEq(wot, "[Str!]")
		reg.callMethod(#callMeList3, this, [ Num?[62] ])
		verifyEq(wot, "[62]")
	}

	Void testMaps() {
		reg := RegistryBuilder().build.startup
		reg.callMethod(#callMeMap, this, [69, Str:Str["Du":"de"]])
		verifyEq(num, 69)
		verifyEq(wot, "[Du:de]")

		verifyErrMsg(IocMessages.providerMethodArgDoesNotFit(Str:Int#, Str:Str#)) {
			reg.callMethod(#callMeMap2, this, [["Du":2]])
		}
		verifyErrMsg(IocMessages.providerMethodArgDoesNotFit(Int:Str#, Str:Str#)) {
			reg.callMethod(#callMeMap2, this, [[4:"de"]])
		}
	}

	Void testLenientMaps() {
		reg := RegistryBuilder().build.startup
		
		// ensure shorthand notation for empty maps still make it through
		reg.callMethod(#callMeMap2, this, [ [:] ])
		verifyEq(wot, "[:]")

		// test type inference - if it *could* fit, it's allowed
		reg.callMethod(#callMeMap2, this, [ Obj:Obj["Du":"de"] ])
		verifyEq(wot, "[Du:de]")
		reg.callMethod(#callMeMap3, this, [ Num:Num?[42:69] ])
		verifyEq(wot, "[42:69]")
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

	Void callMeList(Int num, Obj[]? objs) {
		this.num = num
		this.wot = objs.toStr
	}
	Void callMeList2(Str[] strs) {
		this.wot = strs.toStr
	}
	Void callMeList3(Int[] strs) {
		this.wot = strs.toStr
	}

	Void callMeMap(Int num, Obj:Obj? objs) {
		this.num = num
		this.wot = objs.toStr
	}
	Void callMeMap2(Str:Str strs) {
		this.wot = strs.toStr
	}
	Void callMeMap3(Int:Int strs) {
		this.wot = strs.toStr
	}
}

