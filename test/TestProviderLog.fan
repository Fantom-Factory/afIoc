
// Can't test logging in JS
internal class TestProviderLog : IocTest {

	Void testLogger() {
		reg := threadScope { addModule(T_MyModule97#) }
		s86 := (T_MyService86) reg.serviceById("s86")
		s86.log.warn("Yo!")

		rec := logs.list.last as LogRec
		verifyEq(rec.msg, "Yo!")
		verifyEq(rec.logName, "afIoc")
	}

	Void testLoggerFuncCanChange() {
		reg := threadScope { addModule(T_MyModule97#).addModule(T_MyModule103#) }
		s86 := (T_MyService86) reg.serviceById("s86")
		s86.log.warn("Yo Yo!")

		rec := logs.list.last as LogRec
		verifyEq(rec.msg, "Yo Yo!")
		verifyEq(rec.logName, "T_MyService86")
	}

	Void testCtorLogger() {
		reg := threadScope { addModule(T_MyModule97#) }
		s86 := (T_MyService86_2) reg.serviceById("s86-2")
		s86.log.warn("Yo!")

		rec := logs.list.last as LogRec
		verifyEq(rec.msg, "Yo!")
		verifyEq(rec.logName, "afIoc")
	}

	Void testLogId() {
		reg := threadScope { addModule(T_MyModule97#) }
		s86 := (T_MyService86_3) reg.serviceById("s86-3")
		s86.log.warn("Yo!")

		rec := logs.list.last as LogRec
		verifyEq(rec.msg, "Yo!")
		verifyEq(rec.logName, "slimer.dude")
	}
}

internal const class T_MyModule97 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(T_MyService86#).withId("s86")
		defs.addService(T_MyService86_2#).withId("s86-2")
		defs.addService(T_MyService86_3#).withId("s86-3")
	}
}

internal const class T_MyModule103 {
	Void defineServices(RegistryBuilder registryBuilder) {
		registryBuilder.contributeToServiceType(DependencyProviders#) |Configuration config| {
			config.remove("afIoc.log")
			config.add(MyLogProvider())
		}
	}
}

internal const class MyLogProvider : DependencyProvider {
	override Bool canProvide(Scope currentScope, InjectionCtx ctx) {
		if (ctx.isFieldInjection && !ctx.field.hasFacet(Inject#))
			return false
		if (ctx.isFuncInjection && ctx.isFuncArgReserved)
			return false
		dependencyType := ctx.field?.type ?: ctx.funcParam.type
		return dependencyType.fits(Log#)
	}
	
	override Obj? provide(Scope currentScope, InjectionCtx ctx) {
		return Log.get(ctx.targetType.name)
	}
}


internal class T_MyService86 {
	@Inject 
	Log? log
}
internal const class T_MyService86_2 {
	@Inject 
	const Log log
	new make(|This|in) { in(this) }
}
internal class T_MyService86_3 {
	@Inject { id="slimer.dude" }
	Log? log
}

