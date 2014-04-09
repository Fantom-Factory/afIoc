
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

	Void testAutobuildFieldVals() {
		reg := RegistryBuilder().build.startup
		s94 := (T_MyService94) reg.autobuild(T_MyService94#, Obj#.emptyList, [T_MyService94#latex:"Mask!"])
		verifyEq(s94.latex, "Mask!")
	}

	Void testAutobuildBadFieldVals1() {
		reg := RegistryBuilder().build.startup
		verifyErrMsg(IocMessages.injectionUtils_ctorFieldType_nullValue(T_MyService94#latex)) {			
			reg.autobuild(T_MyService94#, Obj#.emptyList, [T_MyService94#latex:null])
		}
	}

	Void testAutobuildBadFieldVals2() {
		reg := RegistryBuilder().build.startup
		verifyErrMsg(IocMessages.injectionUtils_ctorFieldType_valDoesNotFit(666, T_MyService94#latex)) {			
			reg.autobuild(T_MyService94#, Obj#.emptyList, [T_MyService94#latex:666])
		}
	}

	Void testAutobuildBadFieldVals3() {
		reg := RegistryBuilder().build.startup
		verifyErrMsg(IocMessages.injectionUtils_ctorFieldType_wrongType(T_MyService47#int, T_MyService94#)) {			
			reg.autobuild(T_MyService94#, Obj#.emptyList, [T_MyService47#int:69])
		}
	}
	
	** see http://fantom.org/sidewalk/topic/2256
	Void testAutobuildListFieldVals() {
		reg := RegistryBuilder().build.startup
		s94 := (T_MyService95) reg.autobuild(T_MyService95#, Obj#.emptyList, [T_MyService95#latex:["Mask!"]])
		verifyEq(s94.latex[0], "Mask!")
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

internal const class T_MyService94 {
	@Inject const Registry	registry
			const Str		latex
	new make(|This| inject) {
		inject(this)
	}
}

internal const class T_MyService95 {
	@Inject const Registry	registry
			const Str[]?	latex
	new make(|This| inject) {
		inject(this)
	}
}
