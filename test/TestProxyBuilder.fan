
class TestProxyBuilder : IocTest {
	
	private RegistryImpl? reg
	private ServiceProxyBuilder? spb
	
	override Void setup() {
		reg = (RegistryImpl) RegistryBuilder().addModule(T_MyModule76#).build.startup
		spb = (ServiceProxyBuilder) reg.dependencyByType(ServiceProxyBuilder#)
//		spb = (ServiceProxyBuilder) reg.serviceById("ServiceProxyBuilder")
	}
	
	Void testProxyMethod() {
		s50 := spb.buildProxy(OpTracker(), reg.serviceDefById("s50"))
		verifyEq(s50->dude, "dude")
		verifyEq(s50->inc(5), 6)
	}
	
	Void testNonVirtualMethodsAreNotOverridden() {
		s51 := spb.buildProxy(OpTracker(), reg.serviceDefById("s51"))
		verifyEq(s51->dude, "Don't override me!")
		verifyEq(s51->inc(6), 9)
	}
	
	Void testCanBuildMultipleServices() {
		// don't want any nasty sys::Err: Duplicate pod name: afPlasticProxies
		spb.buildProxy(OpTracker(), reg.serviceDefById("s50"))
		spb.buildProxy(OpTracker(), reg.serviceDefById("s50"))
	}

	Void testVirtualButNotImplementedMethodsAreNotCalled() {
		s52 := spb.buildProxy(OpTracker(), reg.serviceDefById("s52"))
		verifyEq(s52->dude, "Virtual Reality")
		verifyEq(s52->inc(7), 6)
	}
	
	Void testProtectedProxyMethod() {
		s54 := spb.buildProxy(OpTracker(), reg.serviceDefById("s54"))
		verifyEq(s54->dude, "dude")
	}

	Void testCannotProxyInternalMixin() {
		verifyErrMsg(IocMessages.proxiedMixinsMustBePublic(PublicTestTypes.type("T_MyService55"))) {
			spb.buildProxy(OpTracker(), reg.serviceDefById("s55"))
		}
	}
	
	Void testNonConstMixin() {
		spb.buildProxy(OpTracker(), reg.serviceDefById("s56"))
	}
	
	Void testOnlyMixinsAllowed() {
		verifyErrMsg(IocMessages.onlyMixinsCanBeProxied(PublicTestTypes.type("T_MyService57"))) {
			spb.buildProxy(OpTracker(), reg.serviceDefById("s57"))
		}
	}
	
	// FIXME: test fields
}

internal class T_MyModule76 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(PublicTestTypes.type("T_MyService50")).withId("s50")
		binder.bindImpl(PublicTestTypes.type("T_MyService51")).withId("s51")
		binder.bindImpl(PublicTestTypes.type("T_MyService52")).withId("s52")
		binder.bindImpl(PublicTestTypes.type("T_MyService54")).withId("s54")
		binder.bindImpl(PublicTestTypes.type("T_MyService55")).withId("s55")
		binder.bindImpl(PublicTestTypes.type("T_MyService56")).withId("s56")
		binder.bindImpl(PublicTestTypes.type("T_MyService57")).withId("s57")
	}
}
//
//internal const mixin T_MyService54 {
//	internal virtual Str dude() { "Virtual Reality" }
//	abstract Int inc(Int i)
//}
