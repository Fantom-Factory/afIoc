
class TestPlastic : IocTest {
	
	Void testProxyMethod() {
		reg := RegistryBuilder().addModule(T_MyModule76#).build.startup
		
		spb := reg.dependencyByType(ServiceProxyBuilder#) as ServiceProxyBuilder
		
		s50 := spb.buildProxy(T_MyService50#)	// as T_MyService50
		
		Env.cur.err.printLine(s50.typeof.toStr)
		
	}
	
}

internal class T_MyModule76 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService50#).withId("s50")
	}
}

const mixin T_MyService50 {
	abstract Str dude()
	abstract Int inc(Int i)
}

const class T_MyService50Impl : T_MyService50 {
	override Str dude() { "dude" }
	override Int inc(Int i) { i + 1 }
}
