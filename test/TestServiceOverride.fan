
class TestServiceOverride : IocTest {

	Void testAppOverrideById() {
		Registry reg := RegistryBuilder().addModule(T_MyModule58#).build.startup
		s44 := reg.serviceById("s44")
		verify(s44 is T_MyService44Impl2)		
	}

	Void testAppOverrideByType() {
		Registry reg := RegistryBuilder().addModule(T_MyModule58#).build.startup
		s44 := reg.dependencyByType(T_MyService44#)
		verify(s44 is T_MyService44Impl2)
	}

	Void testThreadOverrideNotAllowed() {
		verifyErrMsg(IocMessages.serviceOverrideNotImmutable("s45", T_MyService45Impl2#)) {
			RegistryBuilder().addModule(T_MyModule59#).build.startup
		}
	}

	Void testOverrideWrongType() {
		verifyErrMsg(IocMessages.serviceOverrideDoesNotFitServiceDef("s44", T_MyService12#, T_MyService44#)) {
			reg := RegistryBuilder().addModule(T_MyModule60#).build.startup
			T_MyService44 s44 := reg.serviceById("s44")
		}
	}

	Void testOverrideDoesNotExist() {
		verifyErrMsg(IocMessages.serviceOverrideDoesNotExist("s12", T_MyService12#)) {
			RegistryBuilder().addModule(T_MyModule61#).build.startup
		}
	}
}

internal class T_MyModule58 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService44#).withId("s44")
	}
	@Contribute
	private static Void contributeServiceOverride(MappedConfig config) {
		config.addMapped("s44", config.autobuild(T_MyService44Impl2#))
	}
}

internal const mixin T_MyService44 { virtual Str judge() { "anderson" } }
internal const class T_MyService44Impl : T_MyService44 { }
internal const class T_MyService44Impl2 : T_MyService44 { override Str judge() { "dredd" } }

internal class T_MyModule59 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService45#).withId("s45")
	}
	@Contribute
	private static Void contributeServiceOverride(MappedConfig config) {
		config.addMapped("s45", config.autobuild(T_MyService45Impl2#))
	}
}

internal mixin T_MyService45 { abstract Str? dude; virtual Str judge() { "anderson" } }
internal class T_MyService45Impl : T_MyService45 { override Str? dude }
internal class T_MyService45Impl2 : T_MyService45 { override Str? dude; override Str judge() { "dredd" } }

internal class T_MyModule60 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService44#).withId("s44")
		binder.bindImpl(T_MyService12#).withId("s12")
	}
	@Contribute
	private static Void contributeServiceOverride(MappedConfig config) {
		config.addMapped("s44", config.autobuild(T_MyService12#))
	}
}

internal class T_MyModule61 {
	@Contribute
	private static Void contributeServiceOverride(MappedConfig config) {
		config.addMapped("s12", config.autobuild(T_MyService12#))
	}
}
