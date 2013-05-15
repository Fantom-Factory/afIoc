
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
		// put code in LazyService
		fail
	}
	
}

internal class T_MyModule76 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService50#).withId("s50")
		binder.bindImpl(T_MyService51#).withId("s51")
	}
}

@NoDoc	// bugger, test class needs to be public
const mixin T_MyService50 {
	abstract Str dude()
	abstract Int inc(Int i)
}

@NoDoc	// bugger, test class needs to be public
const class T_MyService50Impl : T_MyService50 {
	override Str dude() { "dude" }
	override Int inc(Int i) { i + 1 }
}

@NoDoc	// bugger, test class needs to be public
const mixin T_MyService51 {
	Str dude() { "Don't override me!" }
	virtual Int inc(Int i) { i + 3 }
}

@NoDoc	// bugger, test class needs to be public
const class T_MyService51Impl : T_MyService51 { }
