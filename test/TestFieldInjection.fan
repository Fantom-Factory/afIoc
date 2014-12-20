
internal class TestFieldInjection : IocTest {

	Void testFieldGathering() {
		ThreadStack.pushAndRun(InjectionTracker.trackerId, OpTracker()) |->| {
			
			// this code is used in InjectionUtils
			fields := InjectionUtils.findInjectableFields(T_MyService106_C#, true)
	
			verifyEq(fields.size, 3)
			verify(fields.contains(T_MyService106_P#.fields.find { it.name == "obj" }))
			verify(fields.contains(T_MyService106_C#.fields.find { it.name == "obj" }))
			verify(fields.contains(T_MyService106_C#obj2))
		}		
	}

	// fails due to http://fantom.org/forum/topic/2383
//	Void testPrivateFieldsAreNotHidden() {
//		fieldList	:= (Obj[]) T_MyService106_C#.inheritance.findAll { it.isClass }.reduce([,]) |Obj[] fields, type| { fields.add(type.fields) } 
//		fieldsAll	:= (Field[]) fieldList.flatten.unique
//		fields		:= fieldsAll.exclude { it.isAbstract || it.isStatic }
//
//		reg := RegistryBuilder().build.startup
//		srv := reg.autobuild(T_MyService106_C#) as T_MyService106_C
//		
//		objP := T_MyService106_P#.fields.find { it.name == "obj" }.get(srv)
//		objC := T_MyService106_C#.fields.find { it.name == "obj" }.get(srv)
//
//		verifyEq(objP.typeof, RegistryStartupImpl#)
//		verifyEq(objC.typeof, RegistryShutdownImpl#)
//
//		// test metadata (facet values) are taken from the subclass
//		verifyEq(srv.obj2.typeof, RegistryShutdownImpl#)
//	}
}

internal abstract class T_MyService106_P {
	@Inject { id="afIoc::RegistryStartup" }
	private Obj? obj

	@Inject { id="afIoc::RegistryStartup" }
	abstract Obj? obj2
}

internal class T_MyService106_C : T_MyService106_P, MyService106_M {
	@Inject { id="afIoc::RegistryShutdown" }
	private Obj? obj
	
	@Inject { id="afIoc::RegistryShutdown" }
	override Obj? obj2
}

internal mixin MyService106_M {
	static const Str name := "wotever"
	abstract Obj? obj2
}

