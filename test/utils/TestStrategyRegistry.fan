
internal class TestStrategyRegistry : IocTest {
	
	Void testDupsError() {
		// need to get the ordering correct
		map := Utils.makeMap(Type#, Obj?#)
		map[Err#] 		= 1
		map[IocErr?#] 	= 2
		map[Err?#] 		= 3
		
		verifyErrMsgAndType(Err#, "Type sys::Err is already mapped to value 1") {
			ap := StrategyRegistry(map)
		}
	}
	
	Void testExactMacth() {
		map := Utils.makeMap(Type#, Obj?#)
		map[IocErr#] 	= 2
		map[Err#] 		= 1
		ap := StrategyRegistry(map)
		
		verifyEq(ap.findExactMatch(Obj#, false), null)
		verifyEq(ap.findExactMatch(Obj?#, false), null)
		verifyEq(ap.findExactMatch(Err#, false), 1)
		verifyEq(ap.findExactMatch(Err?#, false), 1)
		verifyEq(ap.findExactMatch(IocErr#, false), 2)
		verifyEq(ap.findExactMatch(IocErr?#, false), 2)
		verifyEq(ap.findExactMatch(T_InnerIocErr#, false), null)
		verifyEq(ap.findExactMatch(T_InnerIocErr?#, false), null)
		verifyEq(ap.findExactMatch(TestStrategyRegistry?#, false), null)
		
		verifyErrMsgAndType(NotFoundErr#, "Could not find match for Type afIoc::TestStrategyRegistry. Available values = afIoc::IocErr, sys::Err") {   
			verifyEq(ap.findExactMatch(TestStrategyRegistry#), null)
		}

		verifyErrMsgAndType(NotFoundErr#, "Could not find match for Type afIoc::T_InnerIocErr. Available values = afIoc::IocErr, sys::Err") {   
			verifyEq(ap.findExactMatch(T_InnerIocErr#), null)
		}
	}

	Void testBestFit() {
		map := Utils.makeMap(Type#, Obj?#)
		map[IocErr#] 	= 2
		map[Err#] 		= 1
		map[T_StratA#] 	= 3
		ap := StrategyRegistry(map)
		
		verifyEq(ap.findBestFit(Obj#, false), null)
		verifyEq(ap.findBestFit(Obj?#, false), null)
		verifyEq(ap.findBestFit(Err#), 1)
		verifyEq(ap.findBestFit(Err?#), 1)
		verifyEq(ap.findBestFit(IocErr#, false), 2)
		verifyEq(ap.findBestFit(IocErr?#, false), 2)
		verifyEq(ap.findBestFit(T_InnerIocErr#, false), 2)
		verifyEq(ap.findBestFit(T_InnerIocErr?#, false), 2)
		verifyEq(ap.findBestFit(TestStrategyRegistry?#, false), null)

		verifyEq(ap.findBestFit(T_StratB?#, false), 3)
		verifyEq(ap.findBestFit(T_StratA?#, false), 3)	// should find A even though it's not directly in the map
		verifyEq(ap.findBestFit(T_StratC?#, false), 3)
		
		verifyErrMsgAndType(NotFoundErr#, "Could not find match for Type afIoc::TestStrategyRegistry. Available values = afIoc::IocErr, sys::Err, afIoc::T_StratA") {   
			verifyEq(ap.findExactMatch(TestStrategyRegistry#), null)
		}
	}

	static Void main(Str[] args) {
//		Env.cur.err.printLine(T_StratA#.)
		Env.cur.err.printLine(T_StratA#.inheritance)
	}
}

internal const mixin T_StratA { }
internal const class T_StratB : IocErr, T_StratA { 
	new make(Str msg := "", Err? cause := null) : super(msg, cause) {}
}
internal const class T_StratC : T_StratB { 
	new make(Str msg := "", Err? cause := null) : super(msg, cause) {}
}

internal const class T_InnerIocErr : IocErr {
	new make(Str msg := "", Err? cause := null) : super(msg, cause) {}
}