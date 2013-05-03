
class TestAutobuild : IocTest {
	
	Void testAutobuildWithParams() {
		reg := RegistryBuilder().addModule(T_MyModule75#).build.startup
		s47 := reg.autobuild(T_MyService47#, 69, "Beer!") as T_MyService47
		verifyEq(s47.int, 69)
		verifyEq(s47.str, "Beer!")
	}

	Void testAutobuildWithParamsAndServices() {
		reg := RegistryBuilder().addModule(T_MyModule75#).build.startup
		s48 := reg.autobuild(T_MyService48#, 69, "Beer!") as T_MyService48
		verifyEq(s48.s2, reg.serviceById("s2"))
		verifyEq(s48.int, 69)
		verifyEq(s48.str, "Beer!")
	}

	Void testAutobuildWithWrongParams() {
		reg := RegistryBuilder().addModule(T_MyModule75#).build.startup
		verifyErrMsg(IocMessages.providerCtorParamDoesNotFit(Str#, Int#)) {			
			reg.autobuild(T_MyService47#, "Oops!")
		}
	}
}

internal class T_MyModule75 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService2#).withId("s2")
		binder.bindImpl(T_MyService48#)
	}
}

internal class T_MyService47 {
	Int int
	Str str
	new make(Int int, Str str) {
		this.int = int
		this.str = str
	}
}

internal class T_MyService48 {
	@Inject
	T_MyService2 s2
	Int int
	Str str
	new make(Int int, Str str, |This| inject) {
		inject(this)
		this.int = int
		this.str = str
	}
}