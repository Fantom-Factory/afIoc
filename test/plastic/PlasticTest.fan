
abstract class PlasticTest : Test {
	
	Void verifyErrMsg(Str errMsg, |Obj| func) {
		errType := PlasticErr#
		try {
			func(4)
		} catch (Err e) {
			if (!e.typeof.fits(errType)) 
				throw Err("Expected $errType got $e.typeof", e)
			if (e.msg != errMsg)
				throw Err("Expected: \n - $errMsg \nGot: \n - $e.msg")
			return
		}
		throw Err("$errType not thrown")
	}
}
