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
		verifyEq(T_ConstClass.eventRef.val, "registryShutdownHook - root - root")
	}

	Void testScopeCreate() {
		reg := RegistryBuilder() { addScope("thread", true) }.onScopeCreate("thread") |Configuration config| {
			config["test"] = T_ConstClass#scopeCreateHook.func.retype(|->|#)
		}.build
		
		T_ConstClass.eventRef.val = null
		reg.rootScope.createChild("thread") {
			verifyEq(T_ConstClass.eventRef.val, "scopeCreateHook - thread - thread")
		}
		
		T_ConstClass.eventRef.val = null
		reg.rootScope.createChild("thread") {
			verifyEq(T_ConstClass.eventRef.val, "scopeCreateHook - thread - thread")
		}
		
		reg.shutdown

		verifyErrMsg(IocErr#, "onScopeCreate: Could not match glob 'wotever' to any scope: builtIn, root") {
			RegistryBuilder().onScopeCreate("wotever") { }.build
		}
	}

	Void testScopeDestroy() {
		reg := RegistryBuilder() { addScope("thread", true) }.onScopeDestroy("thread") |Configuration config| {
			config["test"] = T_ConstClass#scopeDestroyHook.func.retype(|->|#)
		}.build
		
		T_ConstClass.eventRef.val = null
		reg.rootScope.createChild("thread") {
			verifyEq(T_ConstClass.eventRef.val, null)
		}
		verifyEq(T_ConstClass.eventRef.val, "scopeDestroyHook - thread - thread")
		
		T_ConstClass.eventRef.val = null
		reg.rootScope.createChild("thread") {
			verifyEq(T_ConstClass.eventRef.val, null)
		}
		verifyEq(T_ConstClass.eventRef.val, "scopeDestroyHook - thread - thread")
		
		reg.shutdown

		verifyErrMsg(IocErr#, "onScopeDestroy: Could not match glob 'wotever' to any scope: builtIn, root") {
			RegistryBuilder().onScopeDestroy("wotever") { }.build
		}
	}

	Void testServiceBuild() {
		reg := RegistryBuilder() {
			addScope("thread", true)
			onServiceBuild("s02") |Configuration config| {
				config["test"] = T_ConstClass#serviceBuildHook.func.retype(|->|#)
			}
			addService(T_MyService02#).withId("s02").withScopes(["thread"])
		}.build
		
		reg.rootScope.createChild("thread") |thread| {
			T_ConstClass.eventRef.val = null
			thread.serviceById("s02")
			verifyEq(T_ConstClass.eventRef.val, "serviceBuildHook - s02")
		}
		
		reg.rootScope.createChild("thread") |thread| {
			T_ConstClass.eventRef.val = null
			thread.build(T_MyService02#)
			verifyEq(T_ConstClass.eventRef.val, null)
		}
		
		verifyErrMsg(ServiceNotFoundErr#, "onServiceBuild: Could not match glob 'wotever' to any service") {
			RegistryBuilder().onServiceBuild("wotever") |Configuration config| { }.build
		}
	}

	Void testRegistryLifecyleMethods() {
		reg := RegistryBuilder() {
			addModule(T_MyModule09())
		}.build
	
		verifyEq(T_ConstClass.eventRef.val, "registryStartupHook - root - root")
		
		reg.shutdown
		verifyEq(T_ConstClass.eventRef.val, "registryShutdownHook - root - root")
	}
}

@Js
internal const class T_ConstClass {
	const static AtomicRef eventRef	:= AtomicRef(null)
	
	static Void registryStartupHook(Scope scope) {
		eventRef.val = "registryStartupHook - ${scope.id} - ${scope.registry.activeScope.id}"
	}

	static Void registryShutdownHook(Scope scope) {
		eventRef.val = "registryShutdownHook - ${scope.id} - ${scope.registry.activeScope.id}"
	}

	static Void scopeCreateHook(Scope scope) {
		eventRef.val = "scopeCreateHook - ${scope.id} - ${scope.registry.activeScope.id}"
	}

	static Void scopeDestroyHook(Scope scope) {
		scope.serviceById(Registry#.qname)	// just check we can still use the scope 
		eventRef.val = "scopeDestroyHook - ${scope.id} - ${scope.registry.activeScope.id}"
	}

	static Void serviceBuildHook(Obj? serviceInstance, Scope scope, ServiceDef serviceDef) {
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