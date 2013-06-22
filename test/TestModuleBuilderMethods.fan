
internal class TestModuleBuilderMethods : IocTest {
	
	Void testBuilderMethodMustBeStatic() {
		verifyErrMsg(IocMessages.builderMethodsMustBeStatic(T_MyModule37#buildT1)) {
			RegistryBuilder().addModule(T_MyModule37#).build
		}
	}
	
	Void testBuilderMethod() {
		reg := RegistryBuilder().addModule(T_MyModule04#).build.startup
		T_MyService01 myService1 := reg.serviceById("penguin")
		verifyEq(myService1.service.kick, "Penguin")

		T_MyService01 myService2 := reg.dependencyByType(T_MyService01#)
		verifySame(myService1, myService2)
	}

	Void testBuilderMethodWithParams() {
		reg := RegistryBuilder().addModule(T_MyModule05#).build.startup
		T_MyService01 myService1 := reg.serviceById("penguin")
		verifyEq(myService1.service.kick, "Penguin")

		T_MyService01 myService2 := reg.serviceById("goose")
		verifyEq(myService2.service.kick, "ASS!")

		verifyNotSame(myService1, myService2)
	}
	
	Void testBuilderMethodsMustDefineAnId() {
		verifyErrMsg(IocMessages.buildMethodDoesNotDefineServiceId(T_MyModule07#build)) { 
			RegistryBuilder().addModule(T_MyModule07#).build 
		}
	}
	
	Void testWrongScope1() {
		verifyErrMsg(IocMessages.perAppScopeOnlyForConstClasses(T_MyService01#)) { 
			RegistryBuilder().addModule(T_MyModule21#).build
		}
	}

	Void testWrongScope2() {
		verifyErrMsg(IocMessages.perAppScopeOnlyForConstClasses(T_MyService01#)) { 
			RegistryBuilder().addModule(T_MyModule22#).build
		}
	}
}

internal class T_MyModule04 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService02#)
	}
	
	@Build
	static T_MyService01 buildPenguin() {
		ser2 := T_MyService02()
		ser2.kick = "Penguin"
		ser1 := T_MyService01()
		ser1.service = ser2
		return ser1
	}
}

internal class T_MyModule05 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService02#)
	}
	
	@Build
	static T_MyService01 buildPenguin() {
		ser2 := T_MyService02()
		ser2.kick = "Penguin"
		ser1 := T_MyService01()
		ser1.service = ser2
		return ser1
	}

	@Build
	static T_MyService01 buildGoose(T_MyService02 ser2) {
		ser1 := T_MyService01()
		ser1.service = ser2
		return ser1
	}
}

internal class T_MyModule07 {
	@Build
	static T_MyService01 build() {
		return T_MyService01()
	}
}

internal class T_MyModule21 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService01#).withScope(ServiceScope.perApplication)
	}
}

internal class T_MyModule22 {
	@Build{scope=ServiceScope.perApplication}
	static T_MyService01 buildT1() {
		return T_MyService01()
	}
}

internal class T_MyModule37 {
	@Build
	T_MyService01 buildT1() {
		return T_MyService01()
	}
}
