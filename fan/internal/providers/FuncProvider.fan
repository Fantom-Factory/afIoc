
internal const class FuncProvider : DependencyProvider {
	private const ObjLocator objLocator

	new make(Registry registry) { 
		this.objLocator = (ObjLocator) registry 
	}

	override Bool canProvide(InjectionCtx ctx) {
		// IoC standards dictate that field injection should be denoted by a facet
		if (ctx.injectionKind.isFieldInjection && !ctx.field.hasFacet(Inject#))
			return false

		// The 'R' is to check for a return value - to distinguish it from |This| 
		return ctx.dependencyType.name == "Func" && !ctx.dependencyType.isGeneric && ctx.dependencyType.params.containsKey("R")
	}
	
	override Obj? provide(InjectionCtx ctx) {
		ctx.log("Creating Factory Function for ${ctx.dependencyType.signature}")

		funcType	:= ctx.dependencyType
		depType 	:= funcType.params["R"]
		serviceDef	:= objLocator.serviceDefByType(depType)

		// if a service, build a Lazy Func
		if (serviceDef != null) {
			if (funcType.params.size > 1)
				throw IocErr(IocMessages.funcProvider_mustNotHaveArgs(funcType))

			return |->Obj| {
				serviceDef.getService
			}.retype(funcType).toImmutable
		}
		
		// else build a Factory Func
		func := (Func?) null
		switch (funcType.params.size) {
			case 1:	func = |                       -> Obj| { autobuild(depType, [,                     ]) }
			case 2:	func = |a                      -> Obj| { autobuild(depType, [a                     ]) }
			case 3:	func = |a, b                   -> Obj| { autobuild(depType, [a, b                  ]) }
			case 4:	func = |a, b, c                -> Obj| { autobuild(depType, [a, b, c               ]) }
			case 5:	func = |a, b, c, d             -> Obj| { autobuild(depType, [a, b, c, d            ]) }
			case 6:	func = |a, b, c, d, e          -> Obj| { autobuild(depType, [a, b, c, d, e         ]) }
			case 7:	func = |a, b, c, d, e, f       -> Obj| { autobuild(depType, [a, b, c, d, e, f      ]) }
			case 8:	func = |a, b, c, d, e, f, g    -> Obj| { autobuild(depType, [a, b, c, d, e, f, g   ]) }
			case 9:	func = |a, b, c, d, e, f, g, h -> Obj| { autobuild(depType, [a, b, c, d, e, f, g, h]) }
			default: throw UnsupportedErr("Too many arguments: ${funcType.signature}")
		}
		
		return func.retype(funcType).toImmutable
	}
	
	Obj? autobuild(Type type, Obj?[] args) {
		objLocator.trackAutobuild(type, args, null)
	}
}