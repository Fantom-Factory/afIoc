
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
	
	Void testNoMacth() {
		map := Utils.makeMap(Type#, Int?#)
		map[IocErr#] 	= 2
		map[Err#] 		= 1
		ap := StrategyRegistry(map)

		verifyEq(ap.findExactMatch(Bool#, false), null)
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
		
		verifyErrMsgAndType(NotFoundErr#, "Could not find match for Type afIoc::TestStrategyRegistry.") {
			try {
				ap.findExactMatch(TestStrategyRegistry#)
			} catch (NotFoundErr nfe) {
				verifyEq(nfe.availableValues[0], "afIoc::IocErr")
				verifyEq(nfe.availableValues[1], "sys::Err")
				verifyEq(nfe.availableValues.size, 2)
				throw nfe
			}
		}

		verifyErrMsgAndType(NotFoundErr#, "Could not find match for Type afIoc::T_InnerIocErr.") {   
			try {
				ap.findExactMatch(T_InnerIocErr#)
			} catch (NotFoundErr nfe) {
				verifyEq(nfe.availableValues[0], "afIoc::IocErr")
				verifyEq(nfe.availableValues[1], "sys::Err")
				verifyEq(nfe.availableValues.size, 2)
				throw nfe
			}
		}
	}

	Void testBestFit() {
		map := Utils.makeMap(Type#, Obj?#)
		map[IocErr#] 	= 2
		map[Err#] 		= 1
		map[T_StratA#] 	= 3
		ap := StrategyRegistry(map)

		verifyEq(ap.findClosestParent(Obj#, false), null)
		verifyEq(ap.findClosestParent(Obj?#, false), null)
		verifyEq(ap.findClosestParent(Err#), 1)
		verifyEq(ap.findClosestParent(Err?#), 1)
		verifyEq(ap.findClosestParent(IocErr#, false), 2)
		verifyEq(ap.findClosestParent(IocErr?#, false), 2)
		verifyEq(ap.findClosestParent(T_InnerIocErr#, false), 2)
		verifyEq(ap.findClosestParent(T_InnerIocErr?#, false), 2)
		verifyEq(ap.findClosestParent(TestStrategyRegistry?#, false), null)

		verifyEq(ap.findClosestParent(T_StratB?#, false), 3)
		verifyEq(ap.findClosestParent(T_StratA?#, false), 3)	// should find A even though it's not directly in the map
		verifyEq(ap.findClosestParent(T_StratC?#, false), 3)
		
		verifyErrMsgAndType(NotFoundErr#, "Could not find match for Type afIoc::TestStrategyRegistry.") {
			try {
				ap.findExactMatch(TestStrategyRegistry#)
			} catch (NotFoundErr nfe) {
				verifyEq(nfe.availableValues[0], "afIoc::IocErr")
				verifyEq(nfe.availableValues[1], "afIoc::T_StratA")
				verifyEq(nfe.availableValues[2], "sys::Err")
				verifyEq(nfe.availableValues.size, 3)
				throw nfe				
			}
		}
	}
	
	Void testDocs() {
		strategy := StrategyRegistry([:] { ordered=true; it[Obj#]=1; it[Num#]=2; it[Int#]=3})
		verifyEq(strategy.findClosestParent(Obj#), 1)
		verifyEq(strategy.findClosestParent(Num#), 2)
		verifyEq(strategy.findClosestParent(Float#), 2)

		verifyEq(strategy.findChildren(Obj#),   Obj?[1, 2, 3])
		verifyEq(strategy.findChildren(Num#),   Obj?[2, 3])
		verifyEq(strategy.findChildren(Float#), Obj?[,])
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