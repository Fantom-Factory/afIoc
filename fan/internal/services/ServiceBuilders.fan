
internal const class ServiceBuilders {

	private const InjectionUtils injectionUtils
	
	new make(InjectionUtils injectionUtils) {
		this.injectionUtils = injectionUtils 
	}

	|->Obj| fromBuildMethod(Str serviceId, Method method, Obj? instance := null, Obj[]? args := null) {
		|->Obj| {
			InjectionTracker.track("Creating '$serviceId' via builder method '$method.qname'") |->Obj| {
				injectionUtils.callMethod(method, instance, args)
			}
		}
	}
	
	|->Obj| fromCtorAutobuild(Str serviceId, Type implType, Obj?[]? ctorArgs, [Field:Obj?]? fieldVals) {
		|->Obj| {
			InjectionTracker.track("Creating '$serviceId' via ctor autobuild") |->Obj| {
				InjectionTracker.resetTakenFields
				try {
					ctor	:= findAutobuildConstructor(implType, ctorArgs?.map { it?.typeof })
					target	:= 
					injectionUtils.createViaConstructor(ctor, ctorArgs, fieldVals)
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
	Method? findAutobuildConstructor(Type type, Type?[]? paramTypes) {
		constructors := findConstructors(type)

		if (constructors.isEmpty)
			return null

		if (constructors.size == 1)
			return constructors[0]

		annotated := constructors.findAll |c| {
			c.hasFacet(Inject#)
		}
		if (annotated.size == 1)
			return annotated[0]
		if (annotated.size > 1)
			throw IocErr(IocMessages.onlyOneCtorWithInjectFacetAllowed(type, annotated.size))				

//		// choose the best fit ctor
//		params := constructors.findAll |c1, c2| {
//			
//			return false
////			fix me
//		}

		// Choose a constructor with the most parameters.
		params := constructors.sortr |c1, c2| {
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

