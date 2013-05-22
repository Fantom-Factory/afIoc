
class TestProxyBuilder : IocTest {
	
	private RegistryImpl? reg
	private ServiceProxyBuilder? spb
	
	override Void setup() {
		reg = RegistryBuilder().addModule(T_MyModule76#).build.startup as RegistryImpl
		spb = reg.dependencyByType(ServiceProxyBuilder#) as ServiceProxyBuilder
	}
	
	Void testProxyMethod() {
		s50 := spb.buildProxy(reg.serviceDefById("s50"))
		verifyEq(s50->dude, "dude")
		verifyEq(s50->inc(5), 6)
	}
	
	Void testNonVirtualMethodsAreNotOverridden() {
		s51 := spb.buildProxy(reg.serviceDefById("s51"))
		verifyEq(s51->dude, "Don't override me!")
		verifyEq(s51->inc(6), 9)
	}
	
	Void testCanBuildMultipleServices() {
		// don't want any nasty sys::Err: Duplicate pod name: afPlasticProxies
		spb.buildProxy(reg.serviceDefById("s50"))
		spb.buildProxy(reg.serviceDefById("s50"))
	}

	Void testVirtualButNotImplementedMethodsAreNotCalled() {
		s52 := spb.buildProxy(reg.serviceDefById("s52"))
		verifyEq(s52->dude, "Virtual Reality")
		verifyEq(s52->inc(7), 6)
	}
	
	Void testProtectedProxyMethod() {
		s54 := spb.buildProxy(reg.serviceDefById("s54"))
		verifyEq(s54->dude, "dude")
	}

	Void testCannotProxyInternalMixin() {
		verifyErrMsg(IocMessages.proxiedMixinsMustBePublic(PublicTestTypes.type("T_MyService55"))) {
			spb.buildProxy(reg.serviceDefById("s55"))
		}
	}
	
	Void testNonConstMixin() {
		spb.buildProxy(reg.serviceDefById("s56"))
	}
	
	Void testOnlyMixinsAllowed() {
		verifyErrMsg(IocMessages.onlyMixinsCanBeProxied(PublicTestTypes.type("T_MyService57"))) {
			spb.buildProxy(reg.serviceDefById("s57"))
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

** Bugger, I've got test classes that need to be public!
internal const class PublicTestTypes {
	static const PublicTestTypes instance := PublicTestTypes()
	static Type type(Str typeName) { instance.pod.type(typeName) }
	
	const Str fantomPodCode := 
Str<|
     const mixin T_MyService50 {
          abstract Str dude()
          abstract Int inc(Int i)
     }
     const class T_MyService50Impl : T_MyService50 {
          override Str dude() { "dude"; }
          override Int inc(Int i) { i + 1 }
     }
     
     const mixin T_MyService51 {
          Str dude() { "Don't override me!" }
          virtual Int inc(Int i) { i + 3 }
     }
     const class T_MyService51Impl : T_MyService51 { }
     
     const mixin T_MyService52 {
          virtual Str dude() { "Virtual Reality" }
          abstract Int inc(Int i)
     }
     const class T_MyService52Impl : T_MyService52 {
          override Int inc(Int i) { i - 1 }
     }     

     const mixin T_MyService54 {
          protected abstract Str dude()
     }
     const class T_MyService54Impl : T_MyService54 {
          override Str dude() { "dude"; }
     }   

     internal const mixin T_MyService55 {
          abstract Str dude()
     }
     internal const class T_MyService55Impl : T_MyService55 {
          override Str dude() { "dude"; }
     }   

     mixin T_MyService56 { }
     class T_MyService56Impl : T_MyService56 { }

     class T_MyService57 { }

	|>
	
	private const Pod pod := PlasticPodCompiler().compile(fantomPodCode)
}

    internal const mixin T_MyService54 {
     		internal virtual Str dude() { "Virtual Reality" }
          abstract Int inc(Int i)
     }
