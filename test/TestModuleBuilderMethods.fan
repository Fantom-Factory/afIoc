
internal class TestModuleBuilderMethods : IocTest {
	
	Void testBuilderMethodMustBeStatic() {
		verifyIocErrMsg(IocMessages.builderMethodsMustBeStatic(T_MyModule37#buildT1)) {
			RegistryBuilder().addModule(T_MyModule37#).build
		}
	}
	
	Void testBuilderMethod() {
		reg := RegistryBuilder().addModule(T_MyModule04#).build.startup
		T_MyService01 myService1 := reg.serviceById("T_MyService01")
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
	
	Void testWrongScope1() {
		verifyIocErrMsg(IocMessages.perAppScopeOnlyForConstClasses(T_MyService01#)) { 
			RegistryBuilder().addModule(T_MyModule21#).build
		}
	}

	Void testWrongScope2() {
		verifyIocErrMsg(IocMessages.perAppScopeOnlyForConstClasses(T_MyService01#)) { 
			RegistryBuilder().addModule(T_MyModule22#).build
		}
	}
	
	Void testBuilderMethodAppearsInStackTrace() {
		try {
			reg := RegistryBuilder().addModule(T_MyModule91#).build
			reg.serviceById("t1")
			fail
		} catch (Err e) {
			verify(e.traceToStr.contains("afIoc::T_MyModule91.buildT1"))
		}
	}

}

internal class T_MyModule04 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService02#)
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
		binder.bind(T_MyService02#)
	}
	
	@Build { serviceId = "penguin" }
	static T_MyService01 buildPenguin() {
		ser2 := T_MyService02()
		ser2.kick = "Penguin"
		ser1 := T_MyService01()
		ser1.service = ser2
		return ser1
	}

	@Build { serviceId = "goose" }
	static T_MyService01 buildGoose(T_MyService02 ser2) {
		ser1 := T_MyService01()
		ser1.service = ser2
		return ser1
	}
}

internal class T_MyModule21 {
	static Void bind(ServiceBinder binder) {
		binder.bind(T_MyService01#).withScope(ServiceScope.perApplication)
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

internal class T_MyModule91 {
	@Build { serviceId = "t1" }
	static T_MyService01 buildT1() {
		throw Err("Bugger!")
	}
}
