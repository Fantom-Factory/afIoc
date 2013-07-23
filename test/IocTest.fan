
abstract internal class IocTest : Test {
	
	Void verifyErrMsg(Str errMsg, |Obj| func) {
		verifyErrMsgAndType(IocErr#, errMsg, func)
	}

	Void verifyErrMsgAndType(Type errType, Str errMsg, |Obj| func) {
		try {
			func(4)
			fail("$errType not thrown")
		} catch (Err e) {
			try {
				verify(e.typeof.fits(errType), "Expected $errType got $e.typeof")
				verifyEq(e.msg.split('\n')[0].trim, errMsg.trim, "Expected: \n - $errMsg \nGot: \n - $e.msg")
			} catch (Err failure) {
				throw Err(failure.msg, e)
			}
		}
	}
	
}
