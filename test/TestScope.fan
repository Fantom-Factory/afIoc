
@Js
internal class TestScope : IocTest {
	
	Void testScopeAlreadyDefined() {
		verifyIocErrMsg(ErrMsgs.scopeBuilder_scopeReserved("builtIn")) {
			RegistryBuilder() {
				addScope("builtIn", true)
			}.build
		}

		verifyIocErrMsg(ErrMsgs.scopeBuilder_scopeReserved("root")) {
			RegistryBuilder() {
				addScope("root", true)
			}.build
		}
		
		verifyIocErrMsg(ErrMsgs.regBuilder_scopeAlreadyDefined("BackOnceAgain", RegistryBuilder#, RegistryBuilder#)) {
			RegistryBuilder() {
				addScope("BackOnceAgain", true)
				addScope("BackOnceAgain", true)
			}.build
		}
	}

	Void testBuiltInScopeIsReserved() {
		verifyIocErrMsg(ErrMsgs.serviceBuilder_scopeReserved(T_MyService02#.qname, "builtIn")) {
			RegistryBuilder() {
				addService(T_MyService02#).withScopes(["builtIn"])
			}.build
		}
	}

	Void testScopeNotFound() {
		verifyErrMsg(ArgNotFoundErr#, ErrMsgs.serviceBuilder_scopesNotFound(T_MyService02#.qname, ["notHere"])) {
			RegistryBuilder() {
				addService(T_MyService02#).withScopes(["notHere"])
			}.build
		}

		verifyErrMsg(ArgNotFoundErr#, ErrMsgs.serviceBuilder_scopesNotFound(T_MyService02#.qname, ["notHere"])) {
			RegistryBuilder() {
				addService(T_MyService02#).withScopes(["root", "notHere"])
			}.build
		}

		verifyErrMsg(ArgNotFoundErr#, ErrMsgs.serviceBuilder_scopesNotFound(T_MyService02#.qname, ["notHere", "again"])) {
			RegistryBuilder() {
				addService(T_MyService02#).withScopes(["root", "notHere", "again"])
			}.build
		}
	}

	Void testNoMatchedScope() {
		verifyIocErrMsg(ErrMsgs.serviceBuilder_scopeIsThreaded(T_MyService02#.qname, "constOnly")) {
			RegistryBuilder() {
				addScope("constOnly", false)
				addService(T_MyService02#).withScopes(["constOnly"])
			}.build
		}
		
		verifyIocErrMsg(ErrMsgs.serviceBuilder_noScopesMatched(T_MyService02#.qname, "builtIn constOnly root".split)) {
			reg:=RegistryBuilder() {
				addScope("constOnly", false)
				addService(T_MyService02#)
			}.build
		}
	}

	Void testScopeMatching() {
		reg := RegistryBuilder() {
			addScope("t1", true)
			addScope("t2", true)
			addScope("r1", false)
			addScope("r2", false)
			addService(T_MyService75#)	// const
			addService(T_MyService02#)	// non-const
		}.build
		
		scopes := reg.serviceDefs[T_MyService75#.qname].matchedScopes
		verify(scopes.contains("root"))
		verify(scopes.contains("r1"))
		verify(scopes.contains("r2"))
		verify(scopes.size == 3)

		scopes = reg.serviceDefs[T_MyService02#.qname].matchedScopes
		verify(scopes.contains("t1"))
		verify(scopes.contains("t2"))
		verify(scopes.size == 2)
	}
}

@Js
internal const class T_MyService75 {}
