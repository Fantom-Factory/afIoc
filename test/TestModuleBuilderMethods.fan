
internal class TestModuleBuilderMethods : IocTest {
	
	Void testBuilderMethodMustBeStatic() {
		verifyErrMsg(IocMessages.builderMethodsMustBeStatic(T_MyModule37#buildT1)) {
			RegistryBuilder().addModule(T_MyModule37#).build
		}
	}
	
	Void testBuilderMethod() {
		reg := RegistryBuilder().addModule(T_MyModule4#).build.startup
		T_MyService1 myService1 := reg.serviceById("penguin")
		verifyEq(myService1.service.kick, "Penguin")

		T_MyService1 myService2 := reg.dependencyByType(T_MyService1#)
		verifySame(myService1, myService2)
	}

	Void testBuilderMethodWithParams() {
		reg := RegistryBuilder().addModule(T_MyModule5#).build.startup
		T_MyService1 myService1 := reg.serviceById("penguin")
		verifyEq(myService1.service.kick, "Penguin")

		T_MyService1 myService2 := reg.serviceById("goose")
		verifyEq(myService2.service.kick, "ASS!")

		verifyNotSame(myService1, myService2)
	}
	
	Void testBuilderMethodsMustDefineAnId() {
		verifyErrMsg(IocMessages.buildMethodDoesNotDefineServiceId(T_MyModule7#build)) { 
			RegistryBuilder().addModule(T_MyModule7#).build 
		}
	}
	
	Void testWrongScope1() {
		verifyErrMsg(IocMessages.perAppScopeOnlyForConstClasses(T_MyService1#)) { 
			RegistryBuilder().addModule(T_MyModule21#).build
		}
	}

	Void testWrongScope2() {
		verifyErrMsg(IocMessages.perAppScopeOnlyForConstClasses(T_MyService1#)) { 
			RegistryBuilder().addModule(T_MyModule22#).build
		}
	}
}

internal class T_MyModule4 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService2#)
	}
	
	@Build
	static T_MyService1 buildPenguin() {
		ser2 := T_MyService2()
		ser2.kick = "Penguin"
		ser1 := T_MyService1()
		ser1.service = ser2
		return ser1
	}
}

internal class T_MyModule5 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService2#)
	}
	
	@Build
	static T_MyService1 buildPenguin() {
		ser2 := T_MyService2()
		ser2.kick = "Penguin"
		ser1 := T_MyService1()
		ser1.service = ser2
		return ser1
	}

	@Build
	static T_MyService1 buildGoose(T_MyService2 ser2) {
		ser1 := T_MyService1()
		ser1.service = ser2
		return ser1
	}
}

internal class T_MyModule7 {
	@Build
	static T_MyService1 build() {
		return T_MyService1()
	}
}

internal class T_MyModule21 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService1#).withScope(ServiceScope.perApplication)
	}
}

internal class T_MyModule22 {
	@Build{scope=ServiceScope.perApplication}
	static T_MyService1 buildT1() {
		return T_MyService1()
	}
}

internal class T_MyModule37 {
	@Build
	T_MyService1 buildT1() {
		return T_MyService1()
	}
}
