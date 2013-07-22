using concurrent

internal class TestPipelineBuilder : IocTest {
	private Registry? 		 reg
	private PipelineBuilder? bob
	private Obj? 			 term
	private Type?			 t75
	private Type?			 t76

	override Void setup() {
		reg 	= RegistryBuilder().build.startup
		bob 	= (PipelineBuilder) reg.dependencyByType(PipelineBuilder#)
		term	= PublicTestTypes.type("T_MyService75Term").make(["T"])
		t75		= PublicTestTypes.type("T_MyService75")
		t76		= PublicTestTypes.type("T_MyService76")		
	}
	
	Void testPipelineBuilder() {
		num1	:= PublicTestTypes.type("T_MyService76Num").make(["1"])
		num2	:= PublicTestTypes.type("T_MyService76Num").make(["2"])
		num3	:= PublicTestTypes.type("T_MyService76Num").make(["3"])
		
		Actor.locals["test"] = ""
		serv	:= bob.build(t75, t76, [num1, num2, num3], term)
		serv->service()
		
		verifyEq(Actor.locals["test"], "123T")
	}

	Void testPipelineBuilderWithOnlyTerm() {
		Actor.locals["test"] = ""
		serv	:= bob.build(t75, t76, [,], term)
		serv->service()
		
		verifyEq(Actor.locals["test"], "T")
	}
	
	Void testPipelineTypeMustBePublic() {
		verifyErrMsg(IocMessages.pipelineTypeMustBePublic("Pipeline", T_MyService77#)) {
			bob.build(T_MyService77#, t76, [,], T_MyService77Impl())
		}
	}
	
	Void testPipelineTypeMustBeMixins() {
		verifyErrMsg(IocMessages.pipelineTypeMustBeMixin("Pipeline", T_MyService78#)) {
			bob.build(T_MyService78#, t76, [,], T_MyService78())
		}

		verifyErrMsg(IocMessages.pipelineTypeMustBeMixin("Pipeline Filter", T_MyService78#)) {
			bob.build(t75, T_MyService78#, [,], term)
		}
	}

	Void testPipelineMustNotDeclareFields() {
		verifyErrMsg(IocMessages.pipelineTypeMustNotDeclareFields(T_MyService79#)) {
			bob.build(T_MyService79#, t76, [,], T_MyService79Impl())
		}
	}

	Void testPipelineTerminatorMustExtendPipelineType() {
		verifyErrMsg(IocMessages.pipelineTerminatorMustExtendPipeline(T_MyService77#, term.typeof)) {
			bob.build(T_MyService77#, t76, [,], term)
		}
	}

	Void testPipelineFiltersMustExtendFilterType() {
		verifyErrMsg(IocMessages.pipelineFilterMustExtendFilter(t76, T_MyService77Impl#)) {
			bob.build(t75, t76, [T_MyService77Impl()], term)
		}
	}

	Void testPipelineFilterMethodMustTakePipelineAsLastArg() {
		verifyErrMsg(IocMessages.pipelineFilterMustDeclareMethod(T_MyService77#, "sys::Bool service(, ${t75.qname} handler)")) {
			bob.build(t75, T_MyService77#, [T_MyService77Impl()], term)
		}
	}
	
}

internal const mixin T_MyService77 { }
internal const class T_MyService77Impl : T_MyService77 { }

internal const class T_MyService78 { }

internal mixin T_MyService79 { 
	abstract Str dude
}
internal class T_MyService79Impl : T_MyService79 {
	override Str dude := ""
}