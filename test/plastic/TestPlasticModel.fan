
class TestPlasticModel : PlasticTest {
	
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

	Void testCanOnlyExtendOneType() {
		plasticModel := PlasticClassModel("TestImpl", false)
		plasticModel.extendMixin(T_PlasticService02#)
		verifyErrMsg(PlasticMsgs.canOnlyExtendOneType("TestImpl", T_PlasticService02#, T_PlasticService03#)) {
			plasticModel.extendMixin(T_PlasticService03#)
		}
	}

	Void testCanOnlyExtendMixins() {
		plasticModel := PlasticClassModel("TestImpl", false)
		verifyErrMsg(PlasticMsgs.canOnlyExtendMixins("TestImpl", T_PlasticService04#)) {
			plasticModel.extendMixin(T_PlasticService04#)
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
		verifyErrMsg(PlasticMsgs.overrideMethodDoesNotBelongToSuperType(Int#abs, T_PlasticService01#)) {
			plasticModel.overrideMethod(Int#abs, "wotever")
		}
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
		verifyErrMsg(PlasticMsgs.overrideFieldDoesNotBelongToSuperType(Int#minVal, T_PlasticService01#)) {
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