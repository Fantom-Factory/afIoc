using afConcurrent::AtomicMap

@Js
internal class TestDependencyProvider : IocTest {
	
	Void testDependencyMustMatchType() {
		scope := threadScope { addModule(T_MyModule56#) }
		verifyIocErrMsg(ErrMsgs.dependencyProviders_dependencyDoesNotFit(Int#, Str?#)) {
			scope.serviceById("s40")
		}
	}

	Void testCtor1() {
		scope := threadScope { addModule(T_MyModule57#) }
		scope.serviceById("s41")
		verifyCtx(scope, Uri#, Type[,], T_MyService41#)
	}

	Void testField1() {
		scope := threadScope { addModule(T_MyModule57#) }
		scope.serviceById("s42")
		verifyCtx(scope, Uri?#, [Inject#], T_MyService42#)
	}

	Void testField2() {
		reg := threadScope { addModule(T_MyModule57#) }
		reg.serviceById("s43")
		verifyCtx(reg, Uri#, Type[,], T_MyService41#)
	}

	Void testNullFieldInConstClass() {
		reg := threadScope { it.addModule(T_MyModule88#) }
		s72 := (T_MyService72) reg.serviceById("s72")
		verifyNull(s72.oops)
	}

	Void testDependencyProvidersCanHaveLazyServices() {
		reg := threadScope { it.addModule(T_MyModule96#) }
		s72 := (T_MyService72) reg.serviceById("s72")
		verifyEq(s72.oops, "Dredd")
	}

	Void testDependencyProvidersServiceIsNotTheBootStrapImp() {
		reg := threadScope { it.addModule(T_MyModule57#) }
		dp	:= (DependencyProviders) reg.serviceById(DependencyProviders#.qname)
		dps	:= dp.dependencyProviders.map { it.typeof }
		// Bugfix: T_DependencyProvider2# existed in the impl held in RegistryImpl, but not in the version injected into other classes!
		verifyTrue(dps.contains(T_DependencyProvider2#))
	}
	
	private Void verifyCtx(Scope reg, Type type, Type[] facets, Type into) {
		dp 	:= reg.serviceById("dp") as T_DependencyProvider2
		fts := (Type[]?) dp.ls["facets"]
		typ := (Type?) dp.ls["type"]
		verifyEq(typ, type)
		verifyEq(fts, facets)
	}
}

@Js
internal const class T_MyModule56 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService40#).withId("s40")
	}
	@Contribute { serviceType=DependencyProviders# }
	static Void contributeDependencyProviders(Configuration config) {
		dp := config.build(T_DependencyProvider1#)
		config.add(dp)
	}
}
@Js
internal class T_MyService40 {
	@Inject	Str? oops
}
@Js
internal const class T_DependencyProvider1 : DependencyProvider {
	override Bool canProvide(Scope scope, InjectionCtx ctx) { (ctx.field?.type ?: ctx.funcParam.type).fits(Str#) }
	override Obj? provide(Scope scope, InjectionCtx ctx) { 69 }
}

@Js
internal const class T_MyModule57 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_DependencyProvider2#).withId("dp").withScopes(["root"])
		defs.addService(T_MyService41#).withId("s41")
		defs.addService(T_MyService42#).withId("s42")
		defs.addService(T_MyService43#).withId("s43")
	}
	@Contribute { serviceType=DependencyProviders# }
	static Void contributeDependencyProviders(Configuration config, T_DependencyProvider2 dp) {
		config.add(dp)
	}
}

@Js
internal class T_MyService41 {
	new make(Uri uri) { }
}
@Js
internal class T_MyService42 {
	@Inject	Uri? oops
}
@Js
internal class T_MyService43 {
	@Inject	T_MyService41? oops
}

@Js
internal const class T_DependencyProvider2 : DependencyProvider {
	const AtomicMap ls := AtomicMap()
	override Bool canProvide(Scope scope, InjectionCtx ctx) {
		return (ctx.field?.type ?: ctx.funcParam.type).fits(Uri#)
	}
	override Obj? provide(Scope scope, InjectionCtx ctx) {
		ls["facets"] = Type[,].addAll(ctx.field?.facets?.map { it.typeof } ?: [,])
		ls["type"] 	 = (ctx.field?.type ?: ctx.funcParam.type)
		return `ass`
	}
}

@Js
internal const class T_DependencyProvider3 : DependencyProvider {
	override Bool canProvide(Scope scope, InjectionCtx ctx) { (ctx.field?.type ?: ctx.funcParam.type).fits(Str?#) }
	override Obj? provide(Scope scope, InjectionCtx ctx) { null }
}

@Js
internal const class T_MyModule88 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService72#).withId("s72")
	}
	@Contribute { serviceType=DependencyProviders# }
	static Void contributeDependencyProviders(Configuration config) {
		config.add(config.build(T_DependencyProvider3#))
	}
}

@Js
internal const class T_MyService72 {
	@Inject	const Str? oops
	new make(|This|in) { in(this) }
}

@Js
internal const class T_MyModule96 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService72#).withId("s72")
		defs.addService(T_MyService84#).withId("s84")
		defs.addService(T_DependencyProvider4#).withId("dp4").withScopes(["root"])
	}
	@Contribute { serviceType=DependencyProviders# }
	static Void contributeDependencyProviders(Configuration config, T_DependencyProvider4 dp) {
		config.add(dp)
	}
}
@Js
internal const class T_DependencyProvider4 : DependencyProvider {
	@Inject const T_MyService84 s84
	new make(|This|in) { in(this) }
	override Bool canProvide(Scope scope, InjectionCtx ctx) {
		s84.judge
		return (ctx.field?.type ?: ctx.funcParam.type).fits(Str?#) 
	}
	override Obj? provide(Scope scope, InjectionCtx ctx) { s84.judge }
}
@Js
internal const mixin T_MyService84 {
	abstract Str judge()
}
@Js
internal const class T_MyService84Impl : T_MyService84 {
	new make(|This|in) { in(this) }
	override Str judge() { "Dredd" }
}
