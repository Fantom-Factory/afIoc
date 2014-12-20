
internal class TestServiceDef : IocTest {

	private SrvDef? srv

	override Void setup() {
		srv = SrvDef {
			it.id 			= "s1"
			it.type			= Num#
			it.buildData	= Int#
			it.scope		= ServiceScope.perApplication
			it.proxy		= ServiceProxy.ifRequired
			it.moduleId		= "wotever"
		}
	}
	
	Void testOverrideWithNothingSet() {
		ovr := SrvDef {
			it.id 			= "o1"
			it.moduleId		= "wotever"			
		}

		srv.applyOverride(ovr)
		
		verifyEq(srv.id,		"s1")
		verifyEq(srv.type,		Num#)
		verifyEq(srv.buildData,	Int#)
		verifyEq(srv.scope,		ServiceScope.perApplication)
		verifyEq(srv.proxy,		ServiceProxy.ifRequired)
		verifyEq(srv.moduleId,	"wotever")
		verifyEq(srv.overridden,true)
	}

	Void testOverrideWithEverythingSet() {
		ovr := SrvDef {
			it.id 			= "o1"
			it.type			= Int#
			it.buildData	= Float#
			it.scope		= ServiceScope.perThread
			it.proxy		= ServiceProxy.always
			it.moduleId		= "bingo"
		}

		srv.applyOverride(ovr)
		
		verifyEq(srv.id,		"s1")
		verifyEq(srv.type,		Num#)
		verifyEq(srv.buildData,	Float#)
		verifyEq(srv.scope,		ServiceScope.perThread)
		verifyEq(srv.proxy,		ServiceProxy.always)
		verifyEq(srv.moduleId,	"wotever")
		verifyEq(srv.overridden,true)
	}

	** Type is set to the return type of a build method 
	Void testErrIfTypeNotFit() {
		ovr := SrvDef {
			it.id 			= "o1"
			it.type			= Uri#
			it.moduleId		= "bingo"
		}

		verifyErrMsg(IocErr#, IocMessages.serviceOverrideDoesNotFitServiceDef("s1", Uri#, Num#)) {
			srv.applyOverride(ovr)
		}
	}

	** BuildData is set to a type for ctor builds 
	Void testErrIfBuildDataNotFit() {
		ovr := SrvDef {
			it.id 			= "o1"
			it.buildData	= Uri#
			it.moduleId		= "bingo"
		}

		verifyErrMsg(IocErr#, IocMessages.serviceOverrideDoesNotFitServiceDef("s1", Uri#, Num#)) {
			srv.applyOverride(ovr)
		}
	}
}
