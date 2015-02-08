
internal class TestFieldInjection : IocTest {

	Void testFieldGathering() {
		ThreadStack.pushAndRun(InjectionTracker.trackerId, OpTracker()) |->| {
			
			// this code is used in InjectionUtils
			fields := InjectionUtils.findInjectableFields(T_MyService106_C#)
	
			verifyEq(fields.size, 3)
			verify(fields.contains(T_MyService106_P#.fields.find { it.name == "obj" }))
			verify(fields.contains(T_MyService106_C#.fields.find { it.name == "obj" }))
			verify(fields.contains(T_MyService106_C#obj2))
		}		
	}

	// fails due to http://fantom.org/forum/topic/2383
	Void testPrivateFieldsAreNotHidden() {
		reg := RegistryBuilder().build.startup
		srv := reg.autobuild(T_MyService106_C#) as T_MyService106_C
		
		verifyEq(srv.parentObj.typeof, RegistryStartupImpl#)
		verifyEq(srv.childObj.typeof,  RegistryShutdownImpl#)

		// test metadata (facet values) are taken from the subclass
		verifyEq(srv.obj2.typeof, RegistryShutdownImpl#)
	}
}

internal abstract class T_MyService106_P {
	@Inject { id="afIoc::RegistryStartup" }
	private Obj? obj

	@Inject { id="afIoc::RegistryStartup" }
	abstract Obj? obj2
	
	Obj? parentObj() {
		this.obj
	}
}

internal class T_MyService106_C : T_MyService106_P, MyService106_M {
	@Inject { id="afIoc::RegistryShutdown" }
	private Obj? obj
	
	@Inject { id="afIoc::RegistryShutdown" }
	override Obj? obj2

	Obj? childObj() {
		this.obj
	}
}

internal mixin MyService106_M {
	static const Str name := "wotever"
	abstract Obj? obj2
}


//// Problem with Fantom 1.0.67
//// see http://fantom.org/forum/topic/2383
//class Parent {
//    private Str? field
//    Void printParent() { echo(field) }
//}
//
//class Child : Parent {
//    private Str? field
//    Void printChild() { echo(field) }
//}
//
//class Wot {
//	Void main() {
//		child := Child()
//		childField  := Child# .fields.find { it.name == "field" }
//		parentField := Parent#.fields.find { it.name == "field" }
//		
//		childField .set(child, "child")
//		parentField.set(child, "parent")
//
//		child.printChild                // --> child
//		child.printParent               // --> parent
//
//		echo( childField .get(child) )  // --> child
//		echo( parentField.get(child) )  // --> child, should be parent
//
//
//	}
//}
