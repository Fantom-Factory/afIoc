
@Js
internal const class FuncProvider : DependencyProvider {

	override Bool canProvide(Scope currentScope, InjectionCtx ctx) {
		// all field service injection should be denoted by a facet
		if (ctx.isFieldInjection && !ctx.field.hasFacet(Inject#))
			return false

		if (ctx.isFuncInjection && ctx.isFuncArgReserved)
			return false
		
		dependencyType := ctx.field?.type ?: ctx.funcParam.type
		
		// The 'R' is to check for a return value - to distinguish it from |This| 
		return dependencyType.name == "Func" && !dependencyType.isGeneric && dependencyType.params.containsKey("R")
	}
	
	override Obj? provide(Scope currentScope, InjectionCtx ctx) {
		opt			:= false
		serId		:= (Str?) null
		depType		:= (Type?) null
		funcType	:= ctx.field?.type ?: ctx.funcParam.type

		if (ctx.isFieldInjection) {
			inject	:= (Inject) Slot#.method("facet").callOn(ctx.field, [Inject#])	// Stoopid F4
			if (inject.id != null)
				serId = inject.id
			else
				depType = inject.type ?: ctx.field.type.params["R"]
			opt = inject.optional
		}

		if (ctx.isFuncInjection) {
			depType = ctx.funcParam.type.params["R"]
		}
		
		
		// TODO: can not differentiate between an optional service and a factory func
		scope		:= (ScopeImpl) currentScope
		
		// Service may be available in a child scope, so check in the registry if it exists 
		serviceDef	:= (ServiceDefImpl?) null
		if (serId != null)
			serviceDef	= scope.registry.serviceDefs_[serId]
		if (serviceDef == null) {
			serviceDef	= serId != null
				? (scope.registry.serviceDefs_.find { it.matchesId(serId) } ?: throw ServiceNotFoundErr(ErrMsgs.funcProvider_couldNotFindService(serId), scope.registry.serviceDefs.keys))
				: scope.registry.serviceDefs_.find { it.matchesType(depType) }
		}

		// if a service, build a Lazy Func
		if (serviceDef != null || depType.toNonNullable == Scope#) {
			if (funcType.params.size > 1)
				throw IocErr(ErrMsgs.funcProvider_mustNotHaveArgs(funcType))

			mySerId 	:= serId
			myDepType	:= depType
			myOpt		:= opt
			reg			:= currentScope.registry
			func		:= |->Obj?| {
				myDepType?.toNonNullable == Scope#
					? reg.activeScope
					: (mySerId != null ? reg.activeScope.serviceById(mySerId, myOpt.not) : reg.activeScope.serviceByType(myDepType, myOpt.not))
			}
			
			echo("returning func $funcType")
			return func.retype(funcType.toNonNullable)
		}
		
		// else build a Factory Func
		reg		:= 	currentScope.registry
		func	:= (Func?) null
		myType	:= depType
		switch (funcType.params.size) {
			case 1:	func = |                       -> Obj| { autobuild(reg, myType, [,                     ]) }
			case 2:	func = |a                      -> Obj| { autobuild(reg, myType, [a                     ]) }
			case 3:	func = |a, b                   -> Obj| { autobuild(reg, myType, [a, b                  ]) }
			case 4:	func = |a, b, c                -> Obj| { autobuild(reg, myType, [a, b, c               ]) }
			case 5:	func = |a, b, c, d             -> Obj| { autobuild(reg, myType, [a, b, c, d            ]) }
			case 6:	func = |a, b, c, d, e          -> Obj| { autobuild(reg, myType, [a, b, c, d, e         ]) }
			case 7:	func = |a, b, c, d, e, f       -> Obj| { autobuild(reg, myType, [a, b, c, d, e, f      ]) }
			case 8:	func = |a, b, c, d, e, f, g    -> Obj| { autobuild(reg, myType, [a, b, c, d, e, f, g   ]) }
			case 9:	func = |a, b, c, d, e, f, g, h -> Obj| { autobuild(reg, myType, [a, b, c, d, e, f, g, h]) }
			default: throw UnsupportedErr("Too many arguments: ${funcType.signature}")
		}
		
		echo("returning func $funcType")
		// .toNonNullable cos nullable types aren't function types
		return func.retype(funcType.toNonNullable)
	}
	
	Obj? autobuild(RegistryImpl registry, Type type, Obj?[] args) {
		registry.autoBuilder.autobuild(registry.activeScope, type, args, null, null)
	}
}