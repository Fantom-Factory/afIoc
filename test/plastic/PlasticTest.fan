
abstract internal class PlasticTest : Test {
	
	Void verifyErrMsg(Str errMsg, |Obj| func) {
		errType := PlasticErr#
		try {
			func(4)
			fail("$errType not thrown")
		} catch (Err e) {
			try {
				verify(e.typeof.fits(errType), "Expected $errType got $e.typeof")
				verifyEq(e.msg, errMsg, "Expected: \n - $errMsg \nGot: \n - $e.msg")
			} catch (Err failure) {
				throw Err(failure.msg, e)
			}
		}
	}
}
