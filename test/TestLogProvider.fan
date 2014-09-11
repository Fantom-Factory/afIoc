using afConcurrent

internal class TestLogProvider : IocTest {
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

	Void testLogger() {
		reg := RegistryBuilder().addModule(T_MyModule97#).build.startup
		s86 := (T_MyService86) reg.serviceById("s86")
		s86.log.warn("Yo!")

		rec := logs.list.last as LogRec
		verifyEq(rec.msg, "Yo!")
		verifyEq(rec.logName, "afIoc")
	}

	Void testLoggerFuncCanChange() {
		reg := RegistryBuilder().addModule(T_MyModule97#).addModule(T_MyModule103#).build.startup
		s86 := (T_MyService86) reg.serviceById("s86")
		s86.log.warn("Yo Yo!")

		rec := logs.list.last as LogRec
		verifyEq(rec.msg, "Yo Yo!")
		verifyEq(rec.logName, "T_MyService86")
	}

	Void testCtorLogger() {
		reg := RegistryBuilder().addModule(T_MyModule97#).build.startup
		s86 := (T_MyService86_2) reg.serviceById("s86-2")
		s86.log.warn("Yo!")

		rec := logs.list.last as LogRec
		verifyEq(rec.msg, "Yo!")
		verifyEq(rec.logName, "afIoc")
	}

	Void testLogId() {
		reg := RegistryBuilder().addModule(T_MyModule97#).build.startup
		s86 := (T_MyService86_3) reg.serviceById("s86-3")
		s86.log.warn("Yo!")

		rec := logs.list.last as LogRec
		verifyEq(rec.msg, "Yo!")
		verifyEq(rec.logName, "slimer.dude")
	}
}

internal class T_MyModule97 {
	static Void defineServices(ServiceDefinitions defs) {
		defs.add(T_MyService86#).withId("s86")
		defs.add(T_MyService86_2#).withId("s86-2")
		defs.add(T_MyService86_3#).withId("s86-3")
	}
}

internal class T_MyModule103 {
	@Override
	static LogProvider overrideLogProvider() {
		return LogProvider.withLogFunc |Type type->Log| { Log.get(type.name) } 
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

