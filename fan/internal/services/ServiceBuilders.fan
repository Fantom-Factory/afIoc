
internal const class ServiceBuilders {

	private const ObjLocator		objLocator
	private const InjectionUtils	injectionUtils
	
	new make(ObjLocator objLocator, InjectionUtils injectionUtils) {
		this.injectionUtils = injectionUtils 
		this.objLocator		= objLocator 
	}

	|->Obj| fromBuildMethod(Str serviceId, Method method, Obj? instance := null, Obj[]? args := null) {
		|->Obj| {
			InjectionTracker.track("Creating '$serviceId' via builder method '$method.qname'") |->Obj| {
				injectionUtils.callMethod(method, instance, args)
			}
		}
	}
	
	|->Obj| fromCtorAutobuild(Str serviceId, Type implType, Obj?[]? ctorArgs, [Field:Obj?]? fieldVals, Bool forService) {
		|->Obj| {
			InjectionTracker.track("Creating '$serviceId' via ctor autobuild") |->Obj| {
				InjectionTracker.resetTakenFields
				try {
					ctor	:= findAutobuildConstructor(implType, ctorArgs?.map { it?.typeof }, forService)
					target	:= 
					injectionUtils.createViaConstructor(implType, ctor, ctorArgs, fieldVals)
					injectionUtils.injectIntoFields(target)
					injectionUtils.callPostInjectMethods(target)
					return target
				} finally {
					InjectionTracker.removeTakenFields					
				}
			}
		}
	}
	
	** A return value of 'null' signifies the type has no ctors and must be instantiated via `Type.make`
	Method? findAutobuildConstructor(Type type, Type?[]? paramTypes, Bool forService) {
		constructors := findConstructors(type)

		// if no ctors, use Type.make()
		if (constructors.isEmpty)
			return null

		// return the @Inject annotated cotor
		annotated := constructors.findAll |c| { c.hasFacet(Inject#) }
		if (annotated.size == 1)
			return annotated[0]
		if (annotated.size > 1)
			throw IocErr(IocMessages.onlyOneCtorWithInjectFacetAllowed(type, annotated.size))				

		// find the best fitting ctors
		ctors := constructors.findAll |ctor| {
			pTypeIndex := 0
			fits := ctor.params.all |param, i| {
				
				// check config type
				if (forService)
					if (i == 0) {
						if (param.type.name == "List")
							return true
						if (param.type.name == "Map")
							return true
					}
				
				// check provided params
				if (paramTypes != null && pTypeIndex < paramTypes.size) {
					pType := paramTypes[pTypeIndex++]
					if (pType == null)
						return param.type.isNullable
					return pType.fits(param.type)
				}
				
				// check service
				a:= InjectionTracker.doingCtorInjection(type, ctor, null) |ctx1->Bool| {
					InjectionTracker.doingParamInjection(ctx1, param, i) |ctx2->Bool| {
						return objLocator.typeMatchesDependency(ctx2)
					}
				}
				return a
			}
			// make sure we use ALL the provided ctor arguments
			if (pTypeIndex < (paramTypes?.size ?: 0))
				fits = false
			return fits
		}

		if (ctors.isEmpty)
			throw IocErr(IocMessages.couldNotFindAutobuildCtor(type, paramTypes))
		
		// there can be only one!
		if (ctors.size == 1)
			return ctors.first
		
		// Choose a constructor with the most parameters.
		params := ctors.sortr |c1, c2| {
			c1.params.size <=> c2.params.size
		}

		if (params[0].params.size == params[1].params.size)
			throw IocErr(IocMessages.ctorsWithSameNoOfParams(type, params[1].params.size))				

		return params[0]
	}

	private static Method[] findConstructors(Type type) { 
		// use fits so nullable types == non-nullable types
		type.methods.findAll |method| { method.isCtor && method.parent.fits(type) }
	}

}

