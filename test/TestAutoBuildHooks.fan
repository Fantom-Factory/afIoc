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

		// test build decorator 
		srv := (T_MyService02?) reg.build(T_MyService02#)
		verifyEq(srv.kick, "head")
		verifyEq(srv.typeof, T_MyService97#)
		
		// test decorator can return null (and why not!?)
		srv = reg.build(T_MyService02#)
		verifyNull(srv)
		
		// test that |->| contributions don't return null
		reg = threadScope { addModule(T_MyModule03#) }
		srv = reg.build(T_MyService02#)
		verifyNotNull(srv)
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
internal class T_MyService97 : T_MyService02 {
	override Str kick	:= "head"
}

@Js
internal const class T_MyModule03 {
	const AtomicInt implCount := AtomicInt(0)
	
	@Contribute{ serviceId="afIoc::AutoBuilderHooks.onBuild" }
	Void cont(Configuration config) {
		config["me"] = |->Obj?| {
			i := implCount.incrementAndGet
			return i == 5 ? null : T_MyService97()
		}
	}
}

@Js
internal const class T_MyModule39 {
	@Contribute{ serviceId="afIoc::AutoBuilderHooks.onBuild" }
	Void cont(Configuration config) {
		config["me"] = |->| {
			return null
		}
	}
}