
abstract internal class IocTest : Test {
	
	override Void setup() {
//		(1..100).each {
//			typeName := "T_MyModule" + it.toStr.padl(2, '0')
//			try Pod.of(this).type(typeName)
//			catch echo("$typeName is free!")
//		}
////		59
//		(1..100).each {
//			typeName := "T_MyService" + it.toStr.padl(2, '0')
//			try Pod.of(this).type(typeName)
//			catch echo("$typeName is free!")
//		}
////		60, 65, 66, 67, 75, 76, 77, 78, 79
	}
	
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
