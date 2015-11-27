
@Js
internal class TestScopeChildScope : IocTest {
	
	Void testScopeExists() {
		verifyErrMsg(ArgNotFoundErr#, ErrMsgs.scope_scopeNotFound("oops")) {
			rootScope.createChildScope("oops") { }
		}
	}
	
	Void testNestedScopesNotAllowed() {
		verifyIocErrMsg(ErrMsgs.scope_scopesMayNotBeNested("thread", "builtIn root thread".split)) {
			threadScope{}.createChildScope("thread") { }
		}
	}

	Void testAppScopeInThreadScopeNotAllowed() {
		scope := threadScope { addScope("booya", false) } 
		verifyIocErrMsg(ErrMsgs.scope_invalidScopeNesting("booya", "thread")) {
			scope.createChildScope("booya") { }
		}
	}

	Void testScopeAlias() {
		scope := threadScope { addScope("booya", true).addAlias("bingo") } 
		scope.createChildScope("bingo") |bingo| {
			verifyEq(bingo.id, "booya")
		}
	}
}
