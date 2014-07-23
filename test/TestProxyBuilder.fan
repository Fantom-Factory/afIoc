using concurrent

internal class TestProxyBuilder : IocTest {
	
	private RegistryImpl? reg
	private ServiceProxyBuilder? spb
	
	override Void setup() {
		reg = (RegistryImpl) RegistryBuilder().addModule(T_MyModule76#).build.startup
		spb = (ServiceProxyBuilder) reg.dependencyByType(ServiceProxyBuilder#)
		
		InjectionTracker.forTesting_push(InjectionTracker(reg))
	}

	override Void teardown() {
		InjectionTracker.forTesting_clear()		
	}

	Void testProxyMethod() {
		s50 := spb.createProxyForService(reg.serviceDefById("s50")) as T_MyService50
		verifyEq(s50.dude, "dude")
		verifyEq(s50.inc(5), 6)
	}
	
	Void testNonVirtualMethodsAreNotOverridden() {
		s51 := spb.createProxyForService(reg.serviceDefById("s51")) as T_MyService51
		verifyEq(s51.dude, "Don't override me!")
		verifyEq(s51.inc(6), 9)
	}
	
	Void testNonVirtualFieldsAreNotOverridden() {
		s99 := spb.createProxyForService(reg.serviceDefById("s99"))
		verifyEq(s99->dude, "Don't override me!")
	}
	
	Void testCanBuildMultipleServices() {
		// don't want any nasty sys::Err: Duplicate pod name: afPlasticProxies
		spb.createProxyForService(reg.serviceDefById("s50"))
		spb.createProxyForService(reg.serviceDefById("s50"))
	}

	Void testVirtualButNotOverriddenMethods() {
		// bizarrely, we *do* override Virtual methods and call it on the impl, but if they're not
		// overridden then we end up calling the mixin method!
		s52 := spb.createProxyForService(reg.serviceDefById("s52")) as T_MyService52
		verifyEq(s52.dude, "Virtual Reality")
		verifyEq(s52.inc(7), 6)
	}
	
	Void testProtectedProxyMethod() {
		s54 := spb.createProxyForService(reg.serviceDefById("s54")) as T_MyService54
		verifyEq(s54.dude, "dude")
	}

	Void testCannotProxyInternalMixin() {
		verifyIocErrMsg(IocMessages.proxiedMixinsMustBePublic(T_MyService55#)) {
			spb.createProxyForService(reg.serviceDefById("s55"))
		}
	}
	
	Void testNonConstMixin() {
		spb.createProxyForService(reg.serviceDefById("s56"))
	}
	
	Void testOnlyMixinsAllowed() {
		verifyIocErrMsg(IocMessages.onlyMixinsCanBeProxied(T_MyService57#)) {
			spb.createProxyForService(reg.serviceDefById("s57"))
		}
	}
	
	Void testPerThreadProxy() {
		s58 := spb.createProxyForService(reg.serviceDefById("s58")) as T_MyService58
		verifyEq(s58.dude, "Stella!")
		
		s58.typeof.field("dude").set(s58, "Pint of Pride")
		verifyEq(s58.dude, "Pint of Pride")

		verifyEq(s58.judge, 69)
	}
	
	Void testWithoutProxy() {
		stats	:= reg.serviceById(ServiceStats#.qname) as ServiceStats
		verifyEq(stats.stats["s64"].lifecycle, ServiceLifecycle.DEFINED)
		s64 	:= reg.serviceById("s64") as T_MyService64
		verifyEq(stats.stats["s64"].lifecycle, ServiceLifecycle.CREATED)
		s64.dude
		verifyEq(stats.stats["s64"].lifecycle, ServiceLifecycle.CREATED)
	}
	
	Void testProxyTypesAreCached() {
		bob		:= reg.serviceById(ServiceProxyBuilder#.qname) as ServiceProxyBuilder
		pType1	:= bob.compileProxyType(T_MyService50#)
		pType2	:= bob.compileProxyType(T_MyService50#)
		verifySame(pType1, pType2)
	}
	
	Void testConstFieldsOnMixin() {
		s83 := spb.createProxyForService(reg.serviceDefById("s83")) as T_MyService83
		verifyEq(s83.dude, "dude")
		verifyEq(s83.inc(5), 6)
	}
}

internal class T_MyModule76 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService50#).withId("s50")
		binder.bind(T_MyService51#).withId("s51")
		binder.bind(T_MyService52#).withId("s52")
		binder.bind(T_MyService54#).withId("s54")
		binder.bind(T_MyService55#).withId("s55")
		binder.bind(T_MyService56#).withId("s56")
		binder.bind(T_MyService57#).withId("s57")
		binder.bind(T_MyService58#).withId("s58")
		binder.bind(T_MyService83#).withId("s83")
		binder.bind(T_MyService64#).withId("s64").withoutProxy
		binder.bind(T_MyService99#).withId("s99")
	}
}

@NoDoc const mixin T_MyService50 {
	abstract Str dude()
	abstract Int inc(Int i)
}
@NoDoc const class T_MyService50Impl : T_MyService50 {
	override Str dude() { "dude"; }
	override Int inc(Int i) { i + 1 }
}

@NoDoc const mixin T_MyService64 {
	abstract Str dude()
}
@NoDoc const class T_MyService64Impl : T_MyService64 {
	override Str dude() { "dude"; }
}

@NoDoc const mixin T_MyService51 {
	Str dude() { "Don't override me!" }
	virtual Int inc(Int i) { i + 3 }
}
@NoDoc const class T_MyService51Impl : T_MyService51 { }

@NoDoc const mixin T_MyService52 {
	virtual Str dude() { "Virtual Reality" }
	abstract Int inc(Int i)
}
@NoDoc const class T_MyService52Impl : T_MyService52 {
	override Int inc(Int i) { i - 1 }
}     

@NoDoc const mixin T_MyService54 {
	protected abstract Str dude()
}
@NoDoc const class T_MyService54Impl : T_MyService54 {
	override Str dude() { "dude"; }
}   

@NoDoc internal const mixin T_MyService55 {
	abstract Str dude()
}
@NoDoc internal const class T_MyService55Impl : T_MyService55 {
	override Str dude() { "dude"; }
}   

@NoDoc mixin T_MyService56 { }
@NoDoc class T_MyService56Impl : T_MyService56 { }

@NoDoc class T_MyService57 { }

@NoDoc mixin T_MyService58 { 
	abstract Str dude
	abstract Int judge()
}
@NoDoc class T_MyService58Impl : T_MyService58 { 
	override Str dude := "Stella!"
	override Int judge := 69
}

@NoDoc const mixin T_MyService83 {
	abstract Str dude
	abstract Int inc(Int i)
}
@NoDoc const class T_MyService83Impl : T_MyService83 {
	override Str dude { get {"dude"} set { } }
	override Int inc(Int i) { i + 1 }
}

@NoDoc const mixin T_MyService99 {
	static const Str dude := "Don't override me!"
}
@NoDoc const class T_MyService99Impl : T_MyService99 { }
