
class TestProxyBuilder : IocTest {
	
	private RegistryImpl? reg
	private ServiceProxyBuilder? spb
	
	override Void setup() {
		reg = (RegistryImpl) RegistryBuilder().addModule(T_MyModule76#).build.startup
		spb = (ServiceProxyBuilder) reg.dependencyByType(ServiceProxyBuilder#)
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
	
	// Weird shenanigans - const fields aren't allowed. Full stop.
	// see http://fantom.org/sidewalk/topic/1921
	// So const mixins can't ever declare fields.
	
	Void testPerThreadProxy() {
		s58 := spb.buildProxy(OpTracker(), reg.serviceDefById("s58"))
		verifyEq(s58->dude, "Stella!")
		
		s58.typeof.field("dude").set(s58, "Pint of Pride")
		verifyEq(s58->dude, "Pint of Pride")

		verifyEq(s58->judge, 69)
	}

	// this test can't be done with out a public test class, but as it's a pretty obvious test
	// we can do without it
//	Void testBuilderMethodsAreProxied() {
//		stats	:= reg.serviceById(ServiceIds.serviceStats) as ServiceStats
//		verifyEq(stats.stats["wickedMC"].lifecycle, ServiceLifecycle.DEFINED)
//
//		IocHelper.debugOperation |->| {
//			
//		s59 	:= reg.serviceById("s59") as T_MyService59
//		verifyEq(stats.stats["wickedMC"].lifecycle, ServiceLifecycle.VIRTUAL)
//
//		verifyEq(s59.wotever->dude, "dude") 
//		verifyEq(stats.stats["wickedMC"].lifecycle, ServiceLifecycle.CREATED)
//		}
//	}
	
	Void testWithoutProxy() {
		stats	:= reg.serviceById(ServiceIds.serviceStats) as ServiceStats
		verifyEq(stats.stats["s64"].lifecycle, ServiceLifecycle.DEFINED)
		s64 	:= reg.serviceById("s64") as T_MyService64
		verifyEq(stats.stats["s64"].lifecycle, ServiceLifecycle.CREATED)
		s64.dude
		verifyEq(stats.stats["s64"].lifecycle, ServiceLifecycle.CREATED)
	}
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
		binder.bindImpl(PublicTestTypes.type("T_MyService58")).withId("s58")
//		binder.bindImpl(T_MyService59#).withId("s59")
		binder.bindImpl(T_MyService64#).withId("s64").withoutProxy
	}
	
//	@Build { scope=ServiceScope.perThread}
//	static T_MyService60 buildWickedMc() {
//		return T_MyService60Impl() 
//	}
}

//	internal class T_MyService59 {
//		@Inject @ServiceId { serviceId="wickedMC" }
//		T_MyService60? wotever
//	}
//	mixin T_MyService60 {
//		abstract Str dude()
//		abstract Int inc(Int i)
//	}
//	class T_MyService60Impl : T_MyService60 {
//		override Str dude() { "dude"; }
//		override Int inc(Int i) { i + 1 }
//	}

	internal const mixin T_MyService64 {
		abstract Str dude()
	}
	internal const class T_MyService64Impl : T_MyService64 {
		override Str dude() { "dude"; }
	}
