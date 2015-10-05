
@Js
internal class TestScopeCallMethod : IocTest {

	Int? num
	Type? type
	Str? wot
	
	override Void setup() {
		num = null
		type = null
		wot = null
	}
	
	Void testCallFunc() {
		func := |Int num, Registry reg->Str| {
			"$reg.typeof.name - $num"
		}
		val := rootScope.callFunc(func, [69])
		verifyEq(val, "RegistryImpl - 69")
	}
	
	Void testCallMethod() {
		rootScope.callMethod(#callMe, this, [69])
		verifyEq(num, 69)
		verifyEq(type, RegistryImpl#)
	}

	Void testCallStaticMethod() {
		val := rootScope.callMethod(#callMeStatic, null, ["Dude"])
		verifyEq(val, "Dude")

		val = rootScope.callMethod(#callMeStatic, this, ["Dude"])
		verifyEq(val, "Dude")
	}

	Void testCallMethodDefaultNull() {
		rootScope := rootScope

		rootScope.callMethod(#callMeDefaultNull, this, [69])
		verifyEq(num, 69)
		verifyEq(type, ScopeImpl#)
		verifyEq(wot, null)

		rootScope.callMethod(#callMeDefaultNull, this, [69, rootScope, "judge"])
		verifyEq(num, 69)
		verifyEq(type, ScopeImpl#)
		verifyEq(wot, "judge")
	}

	Void testCallMethodDefaultVal() {
		reg := rootScope
		
		reg.callMethod(#callMeDefaultVal, this, [69])
		verifyEq(num, 69)
		verifyEq(type, ScopeImpl#)
		verifyEq(wot, "dude")

		reg.callMethod(#callMeDefaultVal, this, [69, reg, "judge"])
		verifyEq(num, 69)
		verifyEq(type, ScopeImpl#)
		verifyEq(wot, "judge")

		// check default params are still injected
		wot = null
		reg.callMethod(#callMeDefaultIoc, this, [69])
		verifyEq(num, 69)
		verifyEq(type, ScopeImpl#)
		verifyEq(wot, null)
	}

	Void testErrsAreUnwrapped() {
		verifyErrMsg(ArgErr#, "Poo") {
			throw ArgErr("Poo")
		}
	}

	Void testLists() {
		reg := rootScope

		reg.callMethod(#callMeList, this, [69, Str["Dude"]])
		verifyEq(num, 69)
		verifyEq(wot, "[Dude]")

		verifyIocErrMsg(ErrMsgs.dependencyProviders_dependencyDoesNotFit(Int[]#, Str[]#)) {
			reg.callMethod(#callMeList2, this, [Int[69]])
		}
	}

	Void testLenientLists() {
		reg := rootScope
		
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
		reg := rootScope

		reg.callMethod(#callMeMap, this, [69, Str:Str["Du":"de"]])
		verifyEq(num, 69)
		verifyEq(wot, "[Du:de]")

		verifyIocErrMsg(ErrMsgs.dependencyProviders_dependencyDoesNotFit(Str:Int#, Str:Str#)) {
			reg.callMethod(#callMeMap2, this, [["Du":2]])
		}
		verifyIocErrMsg(ErrMsgs.dependencyProviders_dependencyDoesNotFit(Int:Str#, Str:Str#)) {
			reg.callMethod(#callMeMap2, this, [[4:"de"]])
		}
	}

	Void testLenientMaps() {
		reg := rootScope
		
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
	static Str callMeStatic(Str val) {
		return val
	}
	Void callMeDefaultNull(Int num, Scope scope, Str? wot := null) {
		this.num = num
		this.type = scope.typeof
		this.wot = wot
	}
	Void callMeDefaultVal(Int num, Scope scope, Str? wot := "dude") {
		this.num = num
		this.type = scope.typeof
		this.wot = wot
	}
	Void callMeDefaultIoc(Int num, Scope? scope := null) {
		this.num = num
		this.type = scope.typeof
	}

	Void callMeList(Int num, Obj[]? objs) {
		this.num = num
		this.wot = objs.toStr
	}
	Void callMeList2(Str[] strs) {
		dude := strs.first?.toStr	// ensure we die if the underlying list is of the wrong type
		this.wot = strs.toStr
	}
	Void callMeList3(Int[] strs) {
		this.wot = strs.toStr
	}

	Void callMeMap(Int num, Obj:Obj? objs) {
		this.num = num
		this.wot = objs.isEmpty ? "[:]" : "[" + objs.join(",") |v, k| { "$k:$v" } + "]"
	}
	Void callMeMap2(Str:Str strs) {
		this.wot = strs.isEmpty ? "[:]" : "[" + strs.join(",") |v, k| { "$k:$v" } + "]"
	}
	Void callMeMap3(Int:Int strs) {
		this.wot = strs.isEmpty ? "[:]" : "[" + strs.join(",") |v, k| { "$k:$v" } + "]"
	}
}

