
@Js
internal const class AutobuildProvider : DependencyProvider {

	override Bool canProvide(Scope currentScope, InjectionCtx ctx) {
		ctx.isFieldInjection && ctx.field.hasFacet(Autobuild#) 
	}
	
	override Obj? provide(Scope currentScope, InjectionCtx ctx) {
		scope 	  := (ScopeImpl) currentScope
		autobuild := (Autobuild) ctx.field.facet(Autobuild#)
		return scope.registry.autoBuilder.autobuild(currentScope, autobuild.implType ?: ctx.field.type, autobuild.ctorArgs, autobuild.fieldVals, null)
	}
}
