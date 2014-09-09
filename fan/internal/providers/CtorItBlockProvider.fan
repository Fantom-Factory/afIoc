
internal const class CtorItBlockProvider : DependencyProvider {
	private const InjectionUtils injectionUtils

	new make(Registry registry) { 
		objLocator := (ObjLocator) registry
		this.injectionUtils = objLocator.injectionUtils
	}

	override Bool canProvide(InjectionCtx ctx) {
		ctx.injectionKind == InjectionKind.ctorInjection && ctx.dependencyType == |This|# && ctx.methodParamIndex == ctx.method.params.size - 1
	}
	
	override Obj? provide(InjectionCtx ctx) {
		injectionUtils.makeCtorInjectionPlan(ctx.injectingIntoType)
	}
}
