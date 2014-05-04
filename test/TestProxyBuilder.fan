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
		s50 := spb.createProxyForService(reg.serviceDefById("s50"))
		verifyEq(s50->dude, "dude")
		verifyEq(s50->inc(5), 6)
	}
	
	Void testNonVirtualMethodsAreNotOverridden() {
		s51 := spb.createProxyForService(reg.serviceDefById("s51"))
		verifyEq(s51->dude, "Don't override me!")
		verifyEq(s51->inc(6), 9)
	}
	
	Void testCanBuildMultipleServices() {
		// don't want any nasty sys::Err: Duplicate pod name: afPlasticProxies
		spb.createProxyForService(reg.serviceDefById("s50"))
		spb.createProxyForService(reg.serviceDefById("s50"))
	}

	Void testVirtualButNotImplementedMethodsAreNotCalled() {
		s52 := spb.createProxyForService(reg.serviceDefById("s52"))
		verifyEq(s52->dude, "Virtual Reality")
		verifyEq(s52->inc(7), 6)
	}
	
	Void testProtectedProxyMethod() {
		s54 := spb.createProxyForService(reg.serviceDefById("s54"))
		verifyEq(s54->dude, "dude")
	}

	Void testCannotProxyInternalMixin() {
		verifyErrMsg(IocMessages.proxiedMixinsMustBePublic(PublicTestTypes.type("T_MyService55"))) {
			spb.createProxyForService(reg.serviceDefById("s55"))
		}
	}
	
	Void testNonConstMixin() {
		spb.createProxyForService(reg.serviceDefById("s56"))
	}
	
	Void testOnlyMixinsAllowed() {
		verifyErrMsg(IocMessages.onlyMixinsCanBeProxied(PublicTestTypes.type("T_MyService57"))) {
			spb.createProxyForService(reg.serviceDefById("s57"))
		}
	}
	
	// Weird shenanigans - const fields aren't allowed. Full stop.
	// see http://fantom.org/sidewalk/topic/1921
	// So const mixins can't ever declare fields.
	Void testPerThreadProxy() {
		s58 := spb.createProxyForService(reg.serviceDefById("s58"))
		verifyEq(s58->dude, "Stella!")
		
		s58.typeof.field("dude").set(s58, "Pint of Pride")
		verifyEq(s58->dude, "Pint of Pride")

		verifyEq(s58->judge, 69)
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
		type	:= PublicTestTypes.type("T_MyService50")
		bob		:= reg.serviceById(ServiceProxyBuilder#.qname) as ServiceProxyBuilder
		pType1	:= bob.compileProxyType(type)
		pType2	:= bob.compileProxyType(type)
		verifySame(pType1, pType2)
	}
	
	Void testConstFieldsOnMixin() {
		s83 := spb.createProxyForService(reg.serviceDefById("s83"))
		verifyEq(s83->dude, "dude")
		verifyEq(s83->inc(5), 6)
	}
}

internal class T_MyModule76 {
	static Void bind(ServiceBinder binder) {
		binder.bind(PublicTestTypes.type("T_MyService50")).withId("s50")
		binder.bind(PublicTestTypes.type("T_MyService51")).withId("s51")
		binder.bind(PublicTestTypes.type("T_MyService52")).withId("s52")
		binder.bind(PublicTestTypes.type("T_MyService54")).withId("s54")
		binder.bind(PublicTestTypes.type("T_MyService55")).withId("s55")
		binder.bind(PublicTestTypes.type("T_MyService56")).withId("s56")
		binder.bind(PublicTestTypes.type("T_MyService57")).withId("s57")
		binder.bind(PublicTestTypes.type("T_MyService58")).withId("s58")
		binder.bind(PublicTestTypes.type("T_MyService83")).withId("s83")
		binder.bind(T_MyService64#).withId("s64").withoutProxy
	}
}


	internal const mixin T_MyService64 {
		abstract Str dude()
	}
	internal const class T_MyService64Impl : T_MyService64 {
		override Str dude() { "dude"; }
	}
