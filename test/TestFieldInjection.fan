
@Js
internal class TestFieldInjection : IocTest {

	Void testPrivateFieldsAreNotHidden() {
		reg := threadScope { addService(T_MyService54#); addService(T_MyService55#) }
		srv := reg.build(T_MyService106_C#) as T_MyService106_C

		verifyEq(srv.parentObj.typeof, T_MyService54#)
		verifyEq(srv.childObj.typeof,  T_MyService55#)

		// TODO: ensure fields are set parent first, child last (search field.set ) 
		// test metadata (facet values) are taken from the subclass
		verifyEq(srv.obj2.typeof, T_MyService55#)
	}
}

@Js
internal class T_MyService54 { }
@Js
internal class T_MyService55 { }

@Js
internal abstract class T_MyService106_P {
	@Inject { type=T_MyService54# }
	private Obj? obj

	@Inject { type=T_MyService54# }
	abstract Obj? obj2
	
	Obj? parentObj() {
		this.obj
	}
}

@Js
internal class T_MyService106_C : T_MyService106_P, MyService106_M {
	@Inject { type=T_MyService55# }
	private Obj? obj
	
	@Inject { type=T_MyService55# }
	override Obj? obj2

	Obj? childObj() {
		this.obj
	}
}

@Js
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
//	}
//}
