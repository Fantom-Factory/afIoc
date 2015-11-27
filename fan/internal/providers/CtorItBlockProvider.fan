
@Js
internal const class CtorItBlockProvider : DependencyProvider {
	
	override Bool canProvide(Scope currentScope, InjectionCtx ctx) {
		ctx.isFuncArgItBlock
	}
	
	override Obj? provide(Scope currentScope, InjectionCtx ctx) {
//		return Obj#with.func	// a sweet idea, but 'undefined' in javascript 
		return |Obj o|{}		// this fits |This| and is handled specially
	}
}
