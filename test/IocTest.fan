
abstract internal class IocTest : Test {
	
	override Void setup() {
		Log.get("afIoc").level = LogLevel.warn
		
//		(1..100).each {
//			typeName := "T_MyModule" + it.toStr.padl(2, '0')
//			try Pod.of(this).type(typeName)
//			catch echo("$typeName is free!")
//		}
////		gone!
//		(1..100).each {
//			typeName := "T_MyService" + it.toStr.padl(2, '0')
//			try Pod.of(this).type(typeName)
//			catch echo("$typeName is free!")
//		}
////		78, 79
	}
	
	Void verifyIocErrMsg(Str errMsg, |Obj| func) {
		verifyErrMsg(IocErr#, errMsg, func)
	}

	Void verifyErrMsg(Type errType, Str errMsg, |Obj| func) {
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
