
@Js
internal class TestScopeChildScope : IocTest {
	
	Void testScopeExists() {
		verifyErrMsg(ArgNotFoundErr#, ErrMsgs.scope_scopeNotFound("oops")) {
			rootScope.createChild("oops") { }
		}
	}
	
	Void testNestedScopesNotAllowed() {
		verifyIocErrMsg(ErrMsgs.scope_scopesMayNotBeNested("thread", "builtIn root thread".split)) {
			threadScope{}.createChild("thread") { }
		}
	}

	Void testAppScopeInThreadScopeNotAllowed() {
		scope := threadScope { addScope("booya", false) } 
		verifyIocErrMsg(ErrMsgs.scope_invalidScopeNesting("booya", "thread")) {
			scope.createChild("booya") { }
		}
	}

	Void testScopeAlias() {
		scope := threadScope { addScope("booya", true).addAlias("bingo") } 
		scope.createChild("bingo") |bingo| {
			verifyEq(bingo.id, "booya")
		}
	}
	
	Void testThatJailBrokenScopesStayActive() {
		if (Env.cur.runtime == "js") return

		run := afConcurrent::Synchronized(concurrent::ActorPool())
		registry := RegistryBuilder() {
		    addScope("myScope")
		}.build
		
		rootScope   := registry.rootScope
		
		run.synchronized |->| {
			// create and jailbreak myScope
			myScope := rootScope.createChild("myScope") |myScope| {
				myScope.jailBreak
			}
			if (myScope != null)
				throw Err("myScope SHOULD be null!??")
		}
		
		// prove that root scope is active by default
		// echo(registry.activeScope)  // --> Scope: root
		verifyEq("Scope: root", registry.activeScope.toStr)
		
		run.synchronized |->| {
			// prove that this thread has myScope active by default!
			// echo(registry.activeScope)  // --> Scope: myScope
			if ("Scope: myScope" != registry.activeScope.toStr)
				throw Err("Scope: myScope != ${registry.activeScope.toStr}")
		}
		
		// all jailbroken scopes must be manually destroyed
		run.synchronized |->| {
			registry.activeScope.destroy
		}		
	}
	
	Void testCreatingNonActiveScopes() {
		registry := RegistryBuilder() {
		    addScope("myScope")
		}.build

		myScope := registry.rootScope.createChild("myScope")
		
		verifyFalse(myScope.isDestroyed)
		
		// verify myScope is not active
		verifyEq("Scope: root", registry.activeScope.toStr)
		
		myScope.destroy
	}
}
