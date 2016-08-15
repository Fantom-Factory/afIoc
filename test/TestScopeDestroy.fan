using concurrent

@Js
internal class TestScopeDestroy : IocTest {
	
	Void testScopeIsDisabledOnceDestroyed() {
		reg := RegistryBuilder() { addScope("thread", true) }.addModule(T_MyModule01#).build
		thread := (Scope?) null
		reg.rootScope.createChild("thread") {
			thread = it.jailBreak
		}
		
		// assert methods are okay before shutdown
		thread.serviceById(T_MyService01#.qname)
		thread.serviceByType(T_MyService01#)
		thread.build(T_MyService01#)
		thread.inject(T_MyService01())

		thread.destroy

		verifyErr(ScopeDestroyedErr#) { thread.serviceById(T_MyService01#.qname) }
		verifyErr(ScopeDestroyedErr#) { thread.serviceByType(T_MyService01#) }
		verifyErr(ScopeDestroyedErr#) { thread.build(T_MyService01#) }
		verifyErr(ScopeDestroyedErr#) { thread.inject(T_MyService01()) }
	}
	
	Void testScopeHookErrors() {
		called := AtomicRef(false)

		// verify onScopeCreate method errs
		reg := RegistryBuilder() {
			it.addScope("myScope")
			it.onScopeCreate("myScope") |config| {
				throw Err("Ha ha ha!")
			}
		}.build
		
		verifyErrMsg(Err#, "Ha ha ha!") {
			reg.rootScope.createChild("myScope") {
				called.val = true
			}
		}
		verifyFalse(called.val)
		
		
		
		// verify onScopeDestroy method errs
		reg = RegistryBuilder() {
			it.addScope("myScope")
			it.onScopeDestroy("myScope") |config| {
				throw Err("Ha ha ha!")
			}
		}.build
		
		verifyErrMsg(Err#, "Ha ha ha!") {
			reg.rootScope.createChild("myScope") { }
		}

		
		
		// verify onScopeCreate hook errs
		called.val = false
		reg = RegistryBuilder() {
			it.addScope("myScope")
			it.onScopeCreate("myScope") |config| {
				config["hook"] = |->| {
					throw Err("Ha ha ha!")
				}
			}
		}.build
		
		verifyErrMsg(Err#, "Ha ha ha!") {
			reg.rootScope.createChild("myScope") {
				called.val = true
			}
		}
		verifyFalse(called.val)
		
		
		
		// verify onScopeDestroy method errs
		reg = RegistryBuilder() {
			it.addScope("myScope")
			it.onScopeDestroy("myScope") |config| {
				config["hook"] = |->| {
					throw Err("Ha ha ha!")
				}
			}
		}.build
		
		verifyErrMsg(Err#, "Ha ha ha!") {
			reg.rootScope.createChild("myScope") { }
		}



		// verify onScopeDestroy is still called if there's an error in onScopeCreate
		called.val = false
		reg = RegistryBuilder() {
			it.addScope("myScope")
			it.onScopeDestroy("myScope") |config| {
				config["hook"] = |->| {
					throw Err("Ha ha ha!")
				}
			}
			it.onScopeDestroy("myScope") |config| {
				called.val = true
			}
		}.build
		
		verifyFalse(called.val)
		verifyErrMsg(Err#, "Ha ha ha!") {
			reg.rootScope.createChild("myScope") { }
		}
		verifyTrue(called.val)
	}
}
