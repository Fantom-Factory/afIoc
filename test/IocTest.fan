
abstract internal class IocTest : Test {
	
	override Void setup() {
		Log.get("afIoc").level = LogLevel.warn
		
//		echo("Free Modules Names")
//		(1..100).each {
//			typeName := "T_MyModule" + it.toStr.padl(2, '0')
//			try Pod.of(this).type(typeName)
//			catch echo("$typeName is free!")
//		}
//		// Gone!
//		
//		echo("Free Service Names")
//		(1..100).each {
//			typeName := "T_MyService" + it.toStr.padl(2, '0')
//			try Pod.of(this).type(typeName)
//			catch echo("$typeName is free!")
//		}
//		// Gone!
	}
	
	Void verifyIocErrMsg(Str errMsg, |Obj| func) {
		verifyErrMsg(IocErr#, errMsg, func)
	}

	Void verifySrvNotFoundErrMsg(Str errMsg, |Obj| func) {
		verifyErrMsg(ServiceNotFoundErr#, errMsg, func)
	}

}
