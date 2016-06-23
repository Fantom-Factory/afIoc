using concurrent

@Js
internal class TestDecoratorHook : IocTest {

	Void testDecorator() {
		reg := RegistryBuilder() {
			decorateService("s87") |Configuration config| {
				config["alt-1"] = |Obj? serviceInstance, Scope scope, ServiceDef serviceDef->Obj?| {
					return T_MyService87Alt(serviceInstance)
				}
			}
			addService(T_MyService87#).withId("s87")
		}.build
		
		s87 := (T_MyService87) reg.rootScope.serviceByType(T_MyService87#)
		verifyEq(s87.typeof, T_MyService87Alt#)
		verifyEq(s87.mrHappy, "Mr Happy / Mr Grumpy")
	}

	Void testDoubleDecorator() {
		reg := RegistryBuilder() {
			decorateService("s87") |Configuration config| {
				config["alt-1"] = |Obj? serviceInstance, Scope scope, ServiceDef serviceDef->Obj?| {
					return T_MyService87Alt(serviceInstance)
				}
				config["alt-2"] = |Obj? serviceInstance, Scope scope, ServiceDef serviceDef->Obj?| {
					return T_MyService87Alt2(serviceInstance)
				}
			}
			addService(T_MyService87#).withId("s87")
		}.build
		
		s87 := (T_MyService87) reg.rootScope.serviceByType(T_MyService87#)
		verifyEq(s87.typeof, T_MyService87Alt2#)
		verifyEq(s87.mrHappy, "Mr Fussy / Mr Happy / Mr Grumpy")
	}
}

@Js
const class T_MyService87 {
	virtual Str mrHappy() { "Mr Grumpy" } 
}

@Js
const class T_MyService87Alt : T_MyService87 {
	const T_MyService87 orig
	
	new make(T_MyService87 orig) {
		this.orig = orig
	}

	override Str mrHappy() { "Mr Happy / ${orig.mrHappy}" } 	
}

@Js
const class T_MyService87Alt2 : T_MyService87 {
	const T_MyService87 orig
	
	new make(T_MyService87 orig) {
		this.orig = orig
	}

	override Str mrHappy() { "Mr Fussy / ${orig.mrHappy}" } 	
}
