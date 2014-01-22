
internal class TestAutobuild : IocTest {
	
	Void testAutobuildWithParams() {
		reg := RegistryBuilder().addModule(T_MyModule75#).build.startup
		s47 := reg.autobuild(T_MyService47#, [69, "Beer!"]) as T_MyService47
		verifyEq(s47.int, 69)
		verifyEq(s47.str, "Beer!")
	}

	Void testAutobuildWithParamsAndServices() {
		reg := RegistryBuilder().addModule(T_MyModule75#).build.startup
		s48 := reg.autobuild(T_MyService48#, [69, "Beer!"]) as T_MyService48
		verifyEq(s48.s2, reg.serviceById("s2"))
		verifyEq(s48.int, 69)
		verifyEq(s48.str, "Beer!")
	}

	Void testAutobuildWithWrongParams() {
		reg := RegistryBuilder().addModule(T_MyModule75#).build.startup
		verifyErrMsg(IocMessages.providerMethodArgDoesNotFit(Str#, Int#)) {			
			reg.autobuild(T_MyService47#, ["Oops!"])
		}
	}

	Void testAutobuildWithList() {
		reg := RegistryBuilder().addModule(T_MyModule75#).build.startup
		Int[] ints := [,]
		// because the list should be passed byRef, I don't want to substitute an empty list of the correct type
		verifyErrMsg(IocMessages.providerMethodArgDoesNotFit(Obj?[]#, Int[]#)) {
			reg.autobuild(T_MyService49#, [ints])
		}
	}

	Void testAutobuildTypeHasToInstantiable() {
		reg := RegistryBuilder().build.startup
		verifyErrMsg(IocMessages.autobuildTypeHasToInstantiable(T_MyService81#)) {
			reg.autobuild(T_MyService81#)
		}
	}

	Void testAutobuildDefaultImpls() {
		reg := RegistryBuilder().build.startup
		s80 := (T_MyService80) reg.autobuild(T_MyService80#)
		verifyEq(s80.dude, "Dude!")
	}
}

internal class T_MyModule75 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService02#).withId("s2")
		binder.bind(T_MyService48#)
		binder.bind(T_MyService49#)
	}
}

internal class T_MyService47 {
	Int int
	Str str
	new make(Int int, Str str) {
		this.int = int
		this.str = str
	}
}

internal class T_MyService48 {
	@Inject
	T_MyService02 s2
	Int int
	Str str
	new make(Int int, Str str, |This| inject) {
		inject(this)
		this.int = int
		this.str = str
	}
}

internal class T_MyService49 {
	Int[] ints
	new make(Int[] ints) {
		this.ints = ints
	}
}

internal mixin T_MyService80 {
	abstract Str dude
}
internal class T_MyService80Impl : T_MyService80 {
	override Str dude := "Dude!"
}

internal mixin T_MyService81 { }