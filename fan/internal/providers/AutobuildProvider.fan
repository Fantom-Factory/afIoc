
@Js
internal const class AutobuildProvider : DependencyProvider {

	override Bool canProvide(Scope currentScope, InjectionCtx ctx) {
		ctx.isFieldInjection && ctx.field.hasFacet(Autobuild#) 
	}
	
	override Obj? provide(Scope currentScope, InjectionCtx ctx) {
		scope 	  := (ScopeImpl) currentScope
		autobuild := (Autobuild) Slot#.method("facet").callOn(ctx.field, [Autobuild#])	// Stoopid F4
		return scope.registry.autoBuilder.autobuild(currentScope, autobuild.implType ?: ctx.field.type, autobuild.ctorArgs, autobuild.fieldVals, null)
	}
}
