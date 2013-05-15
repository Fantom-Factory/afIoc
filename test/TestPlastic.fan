
class TestPlastic : IocTest {
	
	Void testProxyMethod() {
		reg := RegistryBuilder().addModule(T_MyModule76#).build.startup as RegistryImpl
		spb := reg.dependencyByType(ServiceProxyBuilder#) as ServiceProxyBuilder
		s50 := spb.buildProxy(reg.serviceDefById("s50")) as T_MyService50
		verifyEq(s50.dude, "dude")
		verifyEq(s50.inc(5), 6)
	}
	
	Void testNonVirtualMethodsAreNotOverridden() {
		reg := RegistryBuilder().addModule(T_MyModule76#).build.startup as RegistryImpl
		spb := reg.dependencyByType(ServiceProxyBuilder#) as ServiceProxyBuilder
		s51 := spb.buildProxy(reg.serviceDefById("s51")) as T_MyService51
		verifyEq(s51.dude, "Don't override me!")
		verifyEq(s51.inc(6), 9)
	}
	
	Void testCanBuildMultipleServices() {
		// don't want any nasty sys::Err: Duplicate pod name: afPlasticProxies
		reg := RegistryBuilder().addModule(T_MyModule76#).build.startup as RegistryImpl
		spb := reg.dependencyByType(ServiceProxyBuilder#) as ServiceProxyBuilder
		spb.buildProxy(reg.serviceDefById("s50"))
		spb.buildProxy(reg.serviceDefById("s50"))
	}

	Void testVirtualButNotImplementedMethodsAreNotCalled() {
		reg := RegistryBuilder().addModule(T_MyModule76#).build.startup as RegistryImpl
		spb := reg.dependencyByType(ServiceProxyBuilder#) as ServiceProxyBuilder
		s52 := spb.buildProxy(reg.serviceDefById("s52")) as T_MyService52
		verifyEq(s52.dude, "Virtual Reality")
		verifyEq(s52.inc(7), 6)
	}
	
}

internal class T_MyModule76 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService50#).withId("s50")
		binder.bindImpl(T_MyService51#).withId("s51")
		binder.bindImpl(T_MyService52#).withId("s52")
	}
}

** Bugger, this test class needs to be public!
@NoDoc
const mixin T_MyService50 {
	abstract Str dude()
	abstract Int inc(Int i)
}

** Bugger, this test class needs to be public!
@NoDoc
const class T_MyService50Impl : T_MyService50 {
	override Str dude() { "dude" }
	override Int inc(Int i) { i + 1 }
}

** Bugger, this test class needs to be public!
@NoDoc
const mixin T_MyService51 {
	Str dude() { "Don't override me!" }
	virtual Int inc(Int i) { i + 3 }
}

** Bugger, this test class needs to be public!
@NoDoc
const class T_MyService51Impl : T_MyService51 { }

** Bugger, this test class needs to be public!
@NoDoc
const mixin T_MyService52 {
	virtual Str dude() { "Virtual Reality" }
	abstract Int inc(Int i)
}

** Bugger, this test class needs to be public!
@NoDoc
const class T_MyService52Impl : T_MyService52 {
	override Int inc(Int i) { i - 1 }
}