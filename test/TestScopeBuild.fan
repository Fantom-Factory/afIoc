using concurrent::AtomicInt

@Js
internal class TestScopeBuild : IocTest {

	Void testAutobuildWithParams() {
		reg := RegistryBuilder().build.rootScope
		s47 := reg.build(T_MyService47#, [69, "Beer!"]) as T_MyService47
		verifyEq(s47.int, 69)
		verifyEq(s47.str, "Beer!")
	}

	Void testAutobuildWithParamsAndServices() {
		reg := threadScope { it.addService(T_MyService02#) { it.withId("s02") } } 
		s48 := reg.build(T_MyService48#, [69, "Beer!"]) as T_MyService48
		verifyEq(s48.s2, reg.serviceById("s02"))
		verifyEq(s48.int, 69)
		verifyEq(s48.str, "Beer!")
	}

	Void testAutobuildWithWrongParams() {
		reg := RegistryBuilder().build.rootScope
		verifyErrMsg(IocErr#, ErrMsgs.autobuilder_couldNotFindAutobuildCtor(T_MyService47#, [Str#])) {			
			reg.build(T_MyService47#, ["Oops!"])
		}
	}

	Void testAutobuildDefaultImpls() {
		reg := RegistryBuilder().build.rootScope
		s80 := (T_MyService80) reg.build(T_MyService80#)
		verifyEq(s80.dude, "Dude!")
	}
	
	Void testAutobuildFieldVals() {
		reg := RegistryBuilder().build.rootScope
		s94 := (T_MyService94) reg.build(T_MyService94#, null, [T_MyService94#latex:"Mask!"])
		verifyEq(s94.latex, "Mask!")
	}

	** see http://fantom.org/sidewalk/topic/2256
	Void testAutobuildListFieldVals() {
		reg := RegistryBuilder().build.rootScope
		s95 := (T_MyService95) reg.build(T_MyService95#, Obj#.emptyList, [T_MyService95#latex:["Mask!"]])
		verifyEq(s95.latex[0], "Mask!")
	}

	Void testCanPassOwnItBlock() {
		// NOTE: can not use 2 it-blocks to set const fields - its a fantom restriction
		itBlock := Field.makeSetFunc([T_MyService98#emma:"boobies"])
		s98 := (T_MyService98) RegistryBuilder().build.rootScope.build(T_MyService98#, [itBlock])
		verifyEq(s98.emma, "boobies")
	}

	Void testCanUseNullableItBlock() {
		// BugFix from Morphia
		s78 := (T_MyService78) RegistryBuilder().build.rootScope.build(T_MyService78#, null, [T_MyService78#emma:"boobies"])
		verifyEq(s78.emma, "boobies")
	}

	Void testAutobuildOnlyBuildsTheOnce() {
		s105 := threadScope { it.addService(T_MyService105#) }.serviceById(T_MyService105#.qname) as T_MyService105
		verifyEq(T_MyService105.built.val,  1)
		verifyEq(T_MyService105A.built.val, 1)
	}
	
	Void testWarningWhenAutobuildingService() {
		// log handlers aren't available in Javascript
		if (Env.cur.runtime == "js") return

		reg := threadScope { it.addService(T_MyService02#) { it.withId("s02") } } 
		reg.build(T_MyService02#)
		log := (LogRec?) logs.list.last
		verifyEq(log?.msg, ErrMsgs.autobuilder_warnAutobuildingService(T_MyService02#, "s02"))
	}
	
	Void testAutobuildCtorSelection() {
		srv := (T_MyService107) rootScope.build(T_MyService107#, ["whoop"])
		verifyEq(srv.ctor, "make1")
		
		srv = (T_MyService107) rootScope.build(T_MyService107#, ["whoop", 89])
		verifyEq(srv.ctor, "make2")

		srv = (T_MyService107) rootScope.build(T_MyService107#, [null, 89])
		verifyEq(srv.ctor, "make2")
	}
	
	Void testAutobuildWithListAsFirstParam() {
		// because lists as 1st param clash with service config
		srv := (T_MyService111) rootScope.build(T_MyService111#, [Str["Judge", "Dredd"], 89])
		verifyEq(srv.str, Str["Judge", "Dredd"])
		verifyEq(srv.int, 89)
	}

}

@Js
internal class T_MyService02 {
	Str kick	:= "ASS!"
}

@Js
internal class T_MyService47 {
	Int int
	Str str
	new make(Int int, Str str) {
		this.int = int
		this.str = str
	}
}

@Js
internal class T_MyService48 {
	@Inject	T_MyService02 s2
	Int int
	Str str
	new make(Int int, Str str, |This| inject) {
		inject(this)
		this.int = int
		this.str = str
	}
}

@Js
internal class T_MyService78 {
	Str	emma
	new make(|This|? f := null) {
		f?.call(this)
	}
}

@Js
internal mixin T_MyService80 {
	abstract Str dude
}
@Js
internal class T_MyService80Impl : T_MyService80 {
	override Str dude := "Dude!"
}

@Js
internal const class T_MyService94 {
	@Inject const Registry	registry
			const Str		latex
	new make(|This| inject) {
		inject(this)
	}
}

@Js
internal const class T_MyService95 {
	@Inject const Registry	registry
			const Str[]?	latex
	new make(|This| inject) {
		inject(this)
	}
}

@Js
internal class T_MyService98 {
	@Inject Registry	registry
			Str			emma
	new make(|This| boobies, |This| ioc) {
		boobies(this)
		ioc(this)
	}
}

@Js
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
@Js
internal class T_MyService105A {
	static const AtomicInt built := AtomicInt(0)
	new make() { built.incrementAndGet}
}

@Js
internal class T_MyService107 {
	Str ctor
	new make1(Str str) { ctor = "make1" }
	new make2(Str? str, Int int) { ctor = "make2" }
}

@Js
internal class T_MyService111 {
	Str[] str
	Int	int
	new make(Str[] str, Int int) { this.str = str; this.int = int }
}
