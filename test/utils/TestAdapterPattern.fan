
internal class TestAdapterPattern : IocTest {
	
	Void testDupsError() {
		// need to get the ordering correct
		map := Utils.makeMap(Type#, Obj?#)
		map[Err#] 		= 1
		map[IocErr?#] 	= 2
		map[Err?#] 		= 3
		
		verifyErrMsgAndType(Err#, "Type sys::Err is already mapped to value 1") {
			ap := AdapterPattern(map)
		}
	}
	
	Void testExactMacth() {
		map := Utils.makeMap(Type#, Obj?#)
		map[IocErr#] 	= 2
		map[Err#] 		= 1
		ap := AdapterPattern(map)
		
		verifyEq(ap.findExactMatch(Obj#, false), null)
		verifyEq(ap.findExactMatch(Obj?#, false), null)
		verifyEq(ap.findExactMatch(Err#, false), 1)
		verifyEq(ap.findExactMatch(Err?#, false), 1)
		verifyEq(ap.findExactMatch(IocErr#, false), 2)
		verifyEq(ap.findExactMatch(IocErr?#, false), 2)
		verifyEq(ap.findExactMatch(T_InnerIocErr#, false), null)
		verifyEq(ap.findExactMatch(T_InnerIocErr?#, false), null)
		verifyEq(ap.findExactMatch(TestAdapterPattern?#, false), null)
		
		verifyErrMsgAndType(NotFoundErr#, "Could not find match for Type afIoc::TestAdapterPattern. Available values = afIoc::IocErr, sys::Err") {   
			verifyEq(ap.findExactMatch(TestAdapterPattern#), null)
		}

		verifyErrMsgAndType(NotFoundErr#, "Could not find match for Type afIoc::T_InnerIocErr. Available values = afIoc::IocErr, sys::Err") {   
			verifyEq(ap.findExactMatch(T_InnerIocErr#), null)
		}
	}

	Void testBestFit() {
		map := Utils.makeMap(Type#, Obj?#)
		map[IocErr#] 	= 2
		map[Err#] 		= 1
		ap := AdapterPattern(map)
		
		verifyEq(ap.findBestFit(Obj#, false), null)
		verifyEq(ap.findBestFit(Obj?#, false), null)
		verifyEq(ap.findBestFit(Err#), 1)
		verifyEq(ap.findBestFit(Err?#), 1)
		verifyEq(ap.findBestFit(IocErr#, false), 2)
		verifyEq(ap.findBestFit(IocErr?#, false), 2)
		verifyEq(ap.findBestFit(T_InnerIocErr#, false), 2)
		verifyEq(ap.findBestFit(T_InnerIocErr?#, false), 2)
		verifyEq(ap.findBestFit(TestAdapterPattern?#, false), null)
		
		verifyErrMsgAndType(NotFoundErr#, "Could not find match for Type afIoc::TestAdapterPattern. Available values = afIoc::IocErr, sys::Err") {   
			verifyEq(ap.findExactMatch(TestAdapterPattern#), null)
		}
	}

}

internal const class T_InnerIocErr : IocErr {
	new make(Str msg := "", Err? cause := null) : super(msg, cause) {}
}