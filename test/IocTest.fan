
abstract internal class IocTest : Test {
	
	Void verifyErrMsg(Str errMsg, |Obj| func) {
		verifyErrMsgAndType(IocErr#, errMsg, func)
	}

	Void verifyErrMsgAndType(Type errType, Str errMsg, |Obj| func) {
		try {
			func(4)
			throw Err("$errType not thrown")
		} catch (Err e) {
			if (!e.typeof.fits(errType)) 
				throw Err("Expected $errType got $e.typeof", e)
			verifyEq(e.msg, errMsg)
		}
	}
	
}
