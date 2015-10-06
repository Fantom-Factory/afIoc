using concurrent

@Js
internal class TestLifecyleHooks : IocTest {

	Void testRegistryStartup() {
		Str? onStartup := null
		RegistryBuilder().onRegistryStartup |Configuration config| {
			config["test"] = |Scope scope| {
				// allow mutable funcs on startup
				onStartup = "registryStartupHook - ${scope.id}"
			}
		}.build
		
		verifyEq(onStartup, "registryStartupHook - root")
	}

	Void testRegistryShutdown() {
		reg := RegistryBuilder().onRegistryShutdown |Configuration config| {
			config["test"] = T_ConstClass#registryShutdownHook.func.retype(|->|#)
		}.build
		
		verifyEq(T_ConstClass.eventRef.val, null)
		
		reg.shutdown
		verifyEq(T_ConstClass.eventRef.val, "registryShutdownHook - root")
	}

	Void testScopeCreate() {
		reg := RegistryBuilder() { addScope("thread", true) }.onScopeCreate("thread") |Configuration config| {
			config["test"] = T_ConstClass#scopeCreateHook.func.retype(|->|#)
		}.build
		
		T_ConstClass.eventRef.val = null
		reg.rootScope.createChildScope("thread") {
			verifyEq(T_ConstClass.eventRef.val, "scopeCreateHook - root")
		}
		
		T_ConstClass.eventRef.val = null
		reg.rootScope.createChildScope("thread") {
			verifyEq(T_ConstClass.eventRef.val, "scopeCreateHook - root")
		}
		
		reg.shutdown
	}

	Void testScopeDestroy() {
		reg := RegistryBuilder() { addScope("thread", true) }.onScopeDestroy("thread") |Configuration config| {
			config["test"] = T_ConstClass#scopeDestroyHook.func.retype(|->|#)
		}.build
		
		T_ConstClass.eventRef.val = null
		reg.rootScope.createChildScope("thread") {
			verifyEq(T_ConstClass.eventRef.val, null)
		}
		verifyEq(T_ConstClass.eventRef.val, "scopeDestroyHook - root")
		
		T_ConstClass.eventRef.val = null
		reg.rootScope.createChildScope("thread") {
			verifyEq(T_ConstClass.eventRef.val, null)
		}
		verifyEq(T_ConstClass.eventRef.val, "scopeDestroyHook - root")
		
		reg.shutdown
	}

	Void testServiceBuild() {
		reg := RegistryBuilder() {
			addScope("thread", true)
			onServiceBuild("s02") |Configuration config| {
				config["test"] = T_ConstClass#serviceBuildHook.func.retype(|->|#)
			}
			addService(T_MyService02#).withId("s02").withScopes(["thread"])
		}.build
		
		reg.rootScope.createChildScope("thread") |thread| {
			T_ConstClass.eventRef.val = null
			thread.serviceById("s02")
			verifyEq(T_ConstClass.eventRef.val, "serviceBuildHook - s02")
		}
		
		reg.rootScope.createChildScope("thread") |thread| {
			T_ConstClass.eventRef.val = null
			thread.build(T_MyService02#)
			verifyEq(T_ConstClass.eventRef.val, null)
		}
	}

	Void testRegistryLifecyleMethods() {
		reg := RegistryBuilder() {
			addModule(T_MyModule09())
		}.build
	
		verifyEq(T_ConstClass.eventRef.val, "registryStartupHook - root")
		
		reg.shutdown
		verifyEq(T_ConstClass.eventRef.val, "registryShutdownHook - root")
	}
}

@Js
internal const class T_ConstClass {
	const static AtomicRef eventRef	:= AtomicRef(null)
	
	static Void registryStartupHook(Scope scope) {
		eventRef.val = "registryStartupHook - ${scope.id}"
	}

	static Void registryShutdownHook(Scope scope) {
		eventRef.val = "registryShutdownHook - ${scope.id}"
	}

	static Void scopeCreateHook(Scope scope) {
		eventRef.val = "scopeCreateHook - ${scope.id}"
	}

	static Void scopeDestroyHook(Scope scope) {
		eventRef.val = "scopeDestroyHook - ${scope.id}"
	}

	static Void serviceBuildHook(Scope scope, ServiceDef serviceDef, Obj serviceInstance) {
		eventRef.val = "serviceBuildHook - ${serviceDef.id}"
	}
}

@Js
internal const class T_MyModule09 {

	Void onRegistryStartup(Configuration config, Scope scope) {
		config["test"] = |->| {
			T_ConstClass.registryStartupHook(scope)
		}
	}
	
	static Void onRegistryShutdown(Configuration config, Scope scope) {
		config["test"] = |->| {
			T_ConstClass.registryShutdownHook(scope)
		}
	}
}