
class TestFacetServiceId : IocTest {

	Void testFieldInjection() {
		reg := RegistryBuilder().addModule(T_MyModule53#).build.startup
		s33 := reg.dependencyByType(T_MyService33#) as T_MyService33
		IocHelper.debugOperation |->| { 
			
		verifyEq(s33.impl1.wotcha, "Go1")
		verifyEq(s33.impl2.wotcha, "Go2")
		}
	}

	Void testConstCtorInjection() {
		reg := RegistryBuilder().addModule(T_MyModule53#).build.startup
		s35 := reg.dependencyByType(T_MyService35#) as T_MyService35 
		verifyEq(s35.impl1.wotcha, "Go1")
		verifyEq(s35.impl2.wotcha, "Go2")
	}

	Void testServiceTypeMustMatch() {
		reg := RegistryBuilder().addModule(T_MyModule53#).build.startup
		try {
			reg.dependencyByType(T_MyService34#)
			fail
		} catch (IocErr iocErr) {
			msg := Regex<|afPlasticProxy[0-9][0-9][0-9]|>.split(iocErr.msg).join("XXX")
			verifyEq(msg, "Service Id 'impl1' of type XXX::T_MyService32Impl does not fit type ${T_MyService33?#.signature}")
		}
	}
}

internal class T_MyModule53 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService32#, T_MyService32Impl1#).withId("impl1")
		binder.bind(T_MyService32#, T_MyService32Impl2#).withId("impl2")
		binder.bindImpl(T_MyService33#)
		binder.bindImpl(T_MyService34#)
		binder.bindImpl(T_MyService35#)
	}
}

// FIXME: killme
const mixin T_MyService32 {
	abstract Str wotcha()
}
// FIXME: killme
const class T_MyService32Impl1 : T_MyService32 {
	override const Str wotcha := "Go1"
}
// FIXME: killme
const class T_MyService32Impl2 : T_MyService32 {
	override const Str wotcha := "Go2"
}
internal class T_MyService33 {
	@Inject @ServiceId {serviceId="impl1"}
	T_MyService32? impl1
	@Inject @ServiceId {serviceId="impl2"}
	T_MyService32? impl2
}
internal class T_MyService35 {
	@Inject @ServiceId {serviceId="impl1"}
	const T_MyService32? impl1
	@Inject @ServiceId {serviceId="impl2"}
	const T_MyService32? impl2
	new make(|This|di) { di(this) }
}
internal class T_MyService34 {	
	@Inject @ServiceId {serviceId="impl1"}
	T_MyService33? impl1
}
