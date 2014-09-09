
internal const class AutobuildProvider : DependencyProvider {
	private const ObjLocator objLocator

	new make(Registry registry) { 
		this.objLocator = (ObjLocator) registry 
	}

	override Bool canProvide(InjectionCtx ctx) {
		ctx.injectionKind.isFieldInjection && ctx.field.hasFacet(Autobuild#) 
	}
	
	override Obj? provide(InjectionCtx ctx) {
		ctx.log("Autobuilding ${ctx.field.type} from @Autobuild")

		autobuild := (Autobuild) Slot#.method("facet").callOn(ctx.field, [Autobuild#])	// Stoopid F4

		if (autobuild.createProxy)
			return objLocator.trackCreateProxy(ctx.field.type, autobuild.implType, autobuild.ctorArgs, autobuild.fieldVals)

		return objLocator.trackAutobuild(autobuild.implType ?: ctx.field.type, autobuild.ctorArgs, autobuild.fieldVals)
	}
}
