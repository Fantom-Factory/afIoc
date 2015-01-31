using concurrent
using afConcurrent

internal class TestAutobuild : IocTest {
	private static const AtomicList logs := AtomicList()
	private static const |LogRec rec| handler := |LogRec rec| { logs.add(rec) }

	override Void setup() {
		logs.clear
		Log.addHandler(handler)
		Log.get("afIoc").level = LogLevel.warn
	}
	
	override Void teardown() {
		Log.removeHandler(handler)		
	}
	
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
		verifyIocErrMsg(IocMessages.providerMethodArgDoesNotFit(Str#, Int#)) {			
			reg.autobuild(T_MyService47#, ["Oops!"])
		}
	}

	Void testAutobuildTypeHasToInstantiable() {
		reg := RegistryBuilder().build.startup
		verifyIocErrMsg(IocMessages.autobuildTypeHasToInstantiable(T_MyService81#)) {
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
		s94 := (T_MyService94) reg.autobuild(T_MyService94#, null, [T_MyService94#latex:"Mask!"])
		verifyEq(s94.latex, "Mask!")
	}

	Void testAutobuildBadFieldVals1() {
		reg := RegistryBuilder().build.startup
		verifyIocErrMsg(IocMessages.injectionUtils_ctorFieldType_nullValue(T_MyService94#latex)) {			
			reg.autobuild(T_MyService94#, Obj#.emptyList, [T_MyService94#latex:null])
		}
	}

	Void testAutobuildBadFieldVals2() {
		reg := RegistryBuilder().build.startup
		verifyIocErrMsg(IocMessages.injectionUtils_ctorFieldType_valDoesNotFit(666, T_MyService94#latex)) {			
			reg.autobuild(T_MyService94#, Obj#.emptyList, [T_MyService94#latex:666])
		}
	}

	Void testAutobuildBadFieldVals3() {
		reg := RegistryBuilder().build.startup
		verifyIocErrMsg(IocMessages.injectionUtils_ctorFieldType_wrongType(T_MyService47#int, T_MyService94#)) {			
			reg.autobuild(T_MyService94#, Obj#.emptyList, [T_MyService47#int:69])
		}
	}
	
	** see http://fantom.org/sidewalk/topic/2256
	Void testAutobuildListFieldVals() {
		reg := RegistryBuilder().build.startup
		s94 := (T_MyService95) reg.autobuild(T_MyService95#, Obj#.emptyList, [T_MyService95#latex:["Mask!"]])
		verifyEq(s94.latex[0], "Mask!")
	}
	
	Void testCanPassOwnItBlock() {
		// NOTE: can not use 2 it-blocks to set const fields - its a fantom restriction
		itBlock := Field.makeSetFunc([T_MyService98#emma:"boobies"])
		s98 := (T_MyService98) RegistryBuilder().build.autobuild(T_MyService98#, [itBlock])
		verifyEq(s98.emma, "boobies")
	}

	Void testCanUseNullableItBlock() {
		// BugFix from Morphia
		s78 := (T_MyService78) RegistryBuilder().build.autobuild(T_MyService78#, null, [T_MyService78#emma:"boobies"])
		verifyEq(s78.emma, "boobies")
	}
	
	Void testWarningWhenAutobuildingService() {
		reg := RegistryBuilder().addModule(T_MyModule75#).build.startup

		reg.autobuild(T_MyService02#)
		log := (LogRec) logs.list.last
		verifyEq(log.msg, IocMessages.warnAutobuildingService("s2", T_MyService02#))

		reg.createProxy(T_MyService80#)
		log = (LogRec) logs.list.last
		verifyEq(log.msg, IocMessages.warnAutobuildingService(T_MyService80#.qname, T_MyService80#))
	}
	
	Void testAutobuildOnlyBuildsTheOnce() {
		reg := RegistryBuilder().addModule(T_MyModule75#).build.startup
		s105 := reg.serviceById(T_MyService105#.qname) as T_MyService105
		verifyEq(T_MyService105.built.val,  1)
		verifyEq(T_MyService105A.built.val, 1)
	}
}

internal class T_MyModule75 {
	static Void defineServices(ServiceDefinitions defs) {
		defs.add(T_MyService02#).withId("s2")
		defs.add(T_MyService49#)
		defs.add(T_MyService80#)
		defs.add(T_MyService105#)
		defs.add(T_MyService105A#)
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

@NoDoc mixin T_MyService80 {
	abstract Str dude
}
@NoDoc class T_MyService80Impl : T_MyService80 {
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

internal class T_MyService98 {
	@Inject Registry	registry
			Str			emma
	new make(|This| boobies, |This| ioc) {
		boobies(this)
		ioc(this)
	}
}

internal class T_MyService78 {
	Str	emma
	new make(|This|? f := null) {
		f?.call(this)
	}
}

internal class T_MyService105 {
	static const AtomicInt built := AtomicInt(0)
	@Autobuild
	T_MyService105A service {
		set {
			built.incrementAndGet
			&service = it
		}
	}
	new make(|This|? f := null) { f?.call(this)	}
}

internal class T_MyService105A {
	static const AtomicInt built := AtomicInt(0)
	new make() { built.incrementAndGet}
}

