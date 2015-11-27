using concurrent::AtomicInt

@Js
internal class TestAutoBuildHooks : IocTest {

	Void testOnBuildHook() {
		mod := T_MyModule03()
		reg := threadScope { addModule(mod) }

		verifyEq(mod.implCount.val, 0)
		
		reg.build(T_MyService02#)
		verifyEq(mod.implCount.val, 1)

		reg.build(T_MyService02#)
		verifyEq(mod.implCount.val, 2)

		reg.build(T_MyService02#)
		verifyEq(mod.implCount.val, 3)
	}

	Void testImmutableFuncErr() {
		// we forego immutable checks in JS 
		if (Env.cur.runtime == "js") return

		meh := 0
		mod := T_MyModule03()
		verifyErrMsg(ArgErr#, ErrMsgs.autobuilder_funcNotImmutable("afIoc::AutoBuilderHooks.onBuild", "oops")) {
			reg := threadScope { contributeToService("afIoc::AutoBuilderHooks.onBuild") |Configuration config| {
				config["oops"] = |->| {
					meh++
				}
			} }
		}
	}
}

@Js
internal const class T_MyModule03 {
	const AtomicInt implCount := AtomicInt(0)
	
	@Contribute{ serviceId="afIoc::AutoBuilderHooks.onBuild" }
	Void cont(Configuration config) {
		config["me"] = |->| {
			implCount.incrementAndGet
		}
	}
}