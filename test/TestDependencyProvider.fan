
internal class TestDependencyProvider : IocTest {
	
	Void testDependencyMustMatchType() {
		reg := RegistryBuilder().addModule(T_MyModule56#).build
		verifyErrMsg(IocMessages.dependencyDoesNotFit(Int#, Str?#)) {
			reg.serviceById("s40")
		}
	}

	Void testCtor1() {
		reg := RegistryBuilder().addModule(T_MyModule57#).build
		reg.serviceById("s41")
		verifyCtx(reg, Uri#, Type[,], T_MyService41#)
	}

	Void testField1() {
		reg := RegistryBuilder().addModule(T_MyModule57#).build
		reg.serviceById("s42")
		verifyCtx(reg, Uri?#, [Inject#], T_MyService42#)
	}

	Void testField2() {
		reg := RegistryBuilder().addModule(T_MyModule57#).build
		reg.serviceById("s43")
		verifyCtx(reg, Uri#, Type[,], T_MyService41#)
	}

	Void testNullFieldInConstClass() {
		reg := RegistryBuilder().addModule(T_MyModule88#).build
		s72 := (T_MyService72) reg.serviceById("s72")
		verifyNull(s72.oops)
	}

	Void testDependencyProvidersCanHaveLazyServices() {			
		reg := RegistryBuilder().addModule(T_MyModule96#).build
		s72 := (T_MyService72) reg.serviceById("s72")
		verifyEq(s72.oops, "Dredd")
	}

	private Void verifyCtx(Registry reg, Type type, Type[] facets, Type into) {
		dp 	:= reg.serviceById("dp") as T_DependencyProvider2
		ctx := dp.ls["ctx"] as ProviderCtx
		typ := dp.ls["type"] as Type
		verifyEq(typ, type)
		verifyEq(Type[,].addAll(ctx.fieldFacets.map{it.typeof}), facets)
	}
}

internal class T_MyModule56 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService40#).withId("s40")
	}
	@Contribute
	static Void contributeDependencyProviderSource(OrderedConfig config) {
		dp := config.autobuild(T_DependencyProvider1#)
		config.add(dp)
	}
}
internal class T_MyService40 {
	@Inject	Str? oops
}
internal const class T_DependencyProvider1 : DependencyProvider {
	override Bool canProvide(ProviderCtx ctx, Type dependencyType) { dependencyType.fits(Str#) }
	override Obj? provide(ProviderCtx ctx, Type dependencyType) { 69 }
}

internal class T_MyModule57 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_DependencyProvider2#).withId("dp")
		binder.bindImpl(T_MyService41#).withId("s41")
		binder.bindImpl(T_MyService42#).withId("s42")
		binder.bindImpl(T_MyService43#).withId("s43")
	}
	@Contribute
	static Void contributeDependencyProviderSource(OrderedConfig config, T_DependencyProvider2 dp) {
		config.add(dp)
	}
}

internal class T_MyService41 {
	new make(Uri uri) { }
}
internal class T_MyService42 {
	@Inject	Uri? oops
}
internal class T_MyService43 {
	@Inject	T_MyService41? oops
}

internal const class T_DependencyProvider2 : DependencyProvider {
	const ThreadStash ls := ThreadStash(T_DependencyProvider2#.name)
	override Bool canProvide(ProviderCtx ctx, Type dependencyType) {
		ls["ctx"] = ctx
		ls["type"] = dependencyType
		return dependencyType.fits(Uri#)
	}
	override Obj? provide(ProviderCtx ctx, Type dependencyType) { `ass` }
}

internal const class T_DependencyProvider3 : DependencyProvider {
	override Bool canProvide(ProviderCtx ctx, Type dependencyType) { dependencyType.fits(Str?#) }
	override Obj? provide(ProviderCtx ctx, Type dependencyType) { null }
}

internal class T_MyModule88 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService72#).withId("s72")
	}
	@Contribute
	static Void contributeDependencyProviderSource(OrderedConfig config) {
		config.add(config.autobuild(T_DependencyProvider3#))
	}
}

internal const class T_MyService72 {
	@Inject	const Str? oops
	new make(|This|in) { in(this) }
}

internal class T_MyModule96 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService72#).withId("s72")
		binder.bindImpl(T_MyService84#).withId("s84")
		binder.bindImpl(T_DependencyProvider4#).withId("dp4")
	}
	@Contribute
	static Void contributeDependencyProviderSource(OrderedConfig config, T_DependencyProvider4 dp) {
		config.add(dp)
	}
}
internal const class T_DependencyProvider4 : DependencyProvider {
	@Inject const T_MyService84 s84
	new make(|This|in) { in(this) }
	override Bool canProvide(ProviderCtx ctx, Type dependencyType) {s84.judge; return dependencyType.fits(Str?#) }
	override Obj? provide(ProviderCtx ctx, Type dependencyType) { s84.judge }
}
const mixin T_MyService84 {
	abstract Str judge()
}
const class T_MyService84Impl : T_MyService84 {
	new make(|This|in) { in(this) }
	override Str judge() { "Dredd" }
}
