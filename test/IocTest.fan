using afConcurrent::AtomicList

@Js
abstract internal class IocTest : Test {
	static	const AtomicList logs		:= AtomicList()
			const Unsafe handlerRef		:= Unsafe(|LogRec rec| { logs.add(rec) })
				  |LogRec rec| handler() { handlerRef.val }

	override Void setup() {
		// immutable funcs don't exist in JS - can't add log handlers
		if (Env.cur.runtime != "js") {
			logs.clear
			Log.addHandler(handler)
		}
		typeof.pod.log.level = LogLevel.warn
		
//		echo("Free Modules Names")
//		(1..100).each {
//			typeName := "T_MyModule" + it.toStr.padl(2, '0')
//			try Pod.of(this).type(typeName)
//			catch echo("$typeName is free!")
//		}
//		// Gone!
		
//		echo("Free Service Names")
//		(1..100).each {
//			typeName := "T_MyService" + it.toStr.padl(2, '0')
//			try Pod.of(this).type(typeName)
//			catch echo("$typeName is free!")
//		}
//		// Gone!
	}

	override Void teardown() {
		Log.removeHandler(handler)		
	}

	Void verifyIocErrMsg(Str errMsg, |Obj| func) {
		verifyErrMsg(IocErr#, errMsg, func)
	}

	Void verifySrvNotFoundErrMsg(Str errMsg, |Obj| func) {
		verifyErrMsg(ServiceNotFoundErr#, errMsg, func)
	}

	Scope rootScope(|RegistryBuilder|? bobFunc := null) {
		bob := RegistryBuilder()
		bobFunc?.call(bob)
		return bob.build.rootScope
	}
	
	Scope threadScope(|RegistryBuilder| bobFunc) {
		bob := RegistryBuilder() { addScope("thread", true) }
		bobFunc.call(bob)
		
		thread := null
		bob.build.rootScope.createChildScope("thread") {
			thread = it.jailBreak
		}

		return thread
	}
}
