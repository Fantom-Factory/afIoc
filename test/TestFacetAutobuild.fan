
class TestFacetAutobuild : IocTest {
	
	Void testFieldInjection() {
		reg := RegistryBuilder().addModule(T_MyModule55#).build.startup
		s36 := reg.dependencyByType(T_MyService36#) as T_MyService36 
		s37 := reg.dependencyByType(T_MyService37#) as T_MyService37 
		verifySame(s36.ser2, s37.ser2)
		verifyNotSame(s36.auto2, s37.auto2)
		verifyNotSame(s36.ser2, s36.auto2)
		verifyNotSame(s37.ser2, s37.auto2)
	}

	Void testOnlyOneDependencyProviderAllowed() {
		reg := RegistryBuilder().addModule(T_MyModule55#).build.startup
		verifyErrMsg(IocMessages.onlyOneDependencyProviderAllowed(T_MyService2#, [ServiceIdProvider#, AutobuildProvider#])) {
			reg.serviceById("s39")
		}
	}
}

internal class T_MyModule55 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService2#).withId("s2")
		binder.bindImpl(T_MyService36#).withId("s36")
		binder.bindImpl(T_MyService37#).withId("s37")
		binder.bindImpl(T_MyService39#).withId("s39")
	}
}

internal class T_MyService36 {
	@Inject @Autobuild
	T_MyService2? auto2
	@Inject
	T_MyService2? ser2
}
internal class T_MyService37 {
	@Inject @Autobuild
	T_MyService2? auto2
	@Inject
	T_MyService2? ser2
}

internal class T_MyService39 {
	@Inject @ServiceId { serviceId="s2" } @Autobuild
	T_MyService2? ser2	
}
