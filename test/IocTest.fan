
abstract class IocTest : Test {
	
	Void verifyErrMsg(Str errMsg, |Obj| func) {
		errType := IocErr#
		try {
			func(4)
		} catch (Err e) {
			if (!e.typeof.fits(errType)) 
				throw Err("Expected $errType got $e.typeof", e)
			// see http://langref.org/fantom/pattern-matching
//			msg := Regex<|afPlasticProxy[0-9][0-9][0-9]|>.split(e.msg).join("afIoc")
			msg := e.msg
			if (msg != errMsg)
				throw Err("Expected: \n - $errMsg \nGot: \n - $msg")
			return
		}
		throw Err("$errType not thrown")
	}
	
	
}
