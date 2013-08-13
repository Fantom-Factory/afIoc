
internal class TestPlasticModel : PlasticTest {
	
	Void testNonConstProxyCannotOverrideConst() {
		plasticModel := PlasticClassModel("TestImpl", false)
		verifyErrMsg(PlasticMsgs.nonConstTypeCannotSubclassConstType("TestImpl", T_PlasticService01#)) {
			plasticModel.extendMixin(T_PlasticService01#)
		}
	}

	Void testConstProxyCannotOverrideNonConst() {
		plasticModel := PlasticClassModel("TestImpl", true)
		verifyErrMsg(PlasticMsgs.constTypeCannotSubclassNonConstType("TestImpl", T_PlasticService02#)) {
			plasticModel.extendMixin(T_PlasticService02#)
		}
	}

	Void testFieldsForConstTypeMustByConst() {
		plasticModel := PlasticClassModel("TestImpl", true)
		plasticModel.extendMixin(T_PlasticService01#)
		verifyErrMsg(PlasticMsgs.constTypesMustHaveConstFields("TestImpl", T_PlasticService02#, "wotever")) {
			plasticModel.addField(T_PlasticService02#, "wotever")
		}
	}

	Void testOverrideMethodsMustBelongToSuperType() {
		plasticModel := PlasticClassModel("TestImpl", true)
		plasticModel.extendMixin(T_PlasticService01#)
		verifyErrMsg(PlasticMsgs.overrideMethodDoesNotBelongToSuperType(Int#abs, [Obj#, T_PlasticService01#])) {
			plasticModel.overrideMethod(Int#abs, "wotever")
		}
	}

	Void testOverrideMethodMayExistInMixinChain() {
		plasticModel := PlasticClassModel("TestImpl", true)
		plasticModel.extendMixin(T_PlasticService10#)
		plasticModel.overrideMethod(T_PlasticService09#deeDee, "wotever")
	}

	Void testOverrideMethodsMustHaveProtectedScope() {
		plasticModel := PlasticClassModel("TestImpl", false)
		plasticModel.extendMixin(T_PlasticService05#)
		verifyErrMsg(PlasticMsgs.overrideMethodHasWrongScope(T_PlasticService05#oops)) {
			plasticModel.overrideMethod(T_PlasticService05#oops, "wotever")
		}
	}

	Void testOverrideMethodsMustBeVirtual() {
		plasticModel := PlasticClassModel("TestImpl", false)
		plasticModel.extendMixin(T_PlasticService06#)
		verifyErrMsg(PlasticMsgs.overrideMethodsMustBeVirtual(T_PlasticService06#oops)) {
			plasticModel.overrideMethod(T_PlasticService06#oops, "wotever")
		}
	}
	
	Void testOverrideFieldsMustBelongToSuperType() {
		plasticModel := PlasticClassModel("TestImpl", true)
		plasticModel.extendMixin(T_PlasticService01#)
		verifyErrMsg(PlasticMsgs.overrideFieldDoesNotBelongToSuperType(Int#minVal, [Obj#, T_PlasticService01#])) {
			plasticModel.overrideField(Int#minVal, "wotever")
		}
	}
	
	Void testOverrideFieldsMustHaveProtectedScope() {
		plasticModel := PlasticClassModel("TestImpl", false)
		plasticModel.extendMixin(T_PlasticService07#)
		verifyErrMsg(PlasticMsgs.overrideFieldHasWrongScope(T_PlasticService07#oops)) {
			plasticModel.overrideField(T_PlasticService07#oops, "wotever")
		}
	}

	Void testOverrideMethodsCanNotHaveDefParams() {
		plasticModel := PlasticClassModel("TestImpl", false)
		plasticModel.extendMixin(T_PlasticService08#)
		verifyErrMsg(PlasticMsgs.overrideMethodsCanNotHaveDefaultValues(T_PlasticService08#redirect)) {
			plasticModel.overrideMethod(T_PlasticService08#redirect, "wotever")
		}
	}
	
	Void testConstTypeCanHaveFields() {
		plasticModel := PlasticClassModel("TestImpl", true)
		plasticModel.addField(Str#, "wotever")
	}

}

internal const mixin T_PlasticService01 { }

internal mixin T_PlasticService02 { }

internal mixin T_PlasticService03 { }

internal class T_PlasticService04 { }

internal mixin T_PlasticService05 { 
	internal abstract Str oops()
}

internal mixin T_PlasticService06 { 
	Str oops() { "oops" }
}

internal mixin T_PlasticService07 { 
	internal abstract Str oops
}

internal mixin T_PlasticService08 { 
	abstract Void redirect(Uri uri, Int statusCode := 303)
}

internal const mixin T_PlasticService09 {
	abstract Void deeDee()
}

internal const mixin T_PlasticService10 : T_PlasticService09 { }
