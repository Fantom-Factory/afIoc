
internal const class InjectionUtils {
	private const static Log 	log 		:= Utils.getLog(InjectionUtils#)

	static Obj autobuild(InjectionCtx ctx, Type type, Obj?[] ctorArgs) {
		InjectionCtx.track("Autobuilding $type.qname") |->Obj| {
			ctor := findAutobuildConstructor(ctx, type)
			obj  := createViaConstructor(ctx, ctor, type, ctorArgs)
			injectIntoFields(ctx, obj)
			return obj
		}
	}

	** Injects into the fields (of all visibilities) where the @Inject facet is present.
	static Obj injectIntoFields(InjectionCtx ctx, Obj object) {
		InjectionCtx.track("Injecting dependencies into fields of $object.typeof.qname") |->| {
			if (!findFieldsWithFacet(ctx, object.typeof, Inject#, true)
				.reduce(false) |bool, field| {
					InjectionCtx.withFacets(field.facets) |->Bool| {
						dependency := findDependencyByType(ctx, field.type)
						inject(ctx, object, field, dependency)
						return true
					}
				})
				InjectionCtx.log("No injection fields found")
		}

		callPostInjectMethods(ctx, object)
		return object
	}

	static Obj? callMethod(InjectionCtx ctx, Method method, Obj? obj, Obj?[] providedMethodArgs) {
		args := findMethodInjectionParams(ctx, method, providedMethodArgs)
		return InjectionCtx.track("Invoking $method.signature on ${method.parent}...") |->Obj?| {
				return (obj == null) ? method.callList(args) : method.callOn(obj, args)
		}
	}

	** A return value of 'null' signifies the type has no ctors and must be instantiated via `Type.make`
	static Method? findAutobuildConstructor(InjectionCtx ctx, Type type) {
		InjectionCtx.track("Looking for suitable ctor to autobiuld $type.qname") |->Method?| {
			ctor := |->Method?| {
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
				
				// Choose a constructor with the most parameters.
				params := constructors.sortr |c1, c2| {
					c1.params.size <=> c2.params.size
				}
				if (params[0].params.size == params[1].params.size)
					throw IocErr(IocMessages.ctorsWithSameNoOfParams(type, params[1].params.size))				
				
				return params[0]
			}()

			if (ctor == null)
				InjectionCtx.log("Found ${type.name}()")
			else
				InjectionCtx.log("Found ${ctor.signature}")
			return ctor
		}
	}

	static Obj createViaConstructor(InjectionCtx ctx, Method? ctor, Type building, Obj?[] providedCtorArgs) {
		if (ctor == null) {
			return InjectionCtx.track("Instantiating $building via ${building.name}()...") |->Obj| {
				return building.make()
			}
		}
		args := findMethodInjectionParams(ctx, ctor, providedCtorArgs)
		return InjectionCtx.track("Instantiating $building via ${ctor.signature}...") |->Obj| {
			try {
				return ctor.callList(args)
			
			// this is such a common err, we treat it as our own to remove Ioc stack frames
			} catch (FieldNotSetErr e) {
				throw IocErr(IocMessages.fieldNotSetErr(e.msg, ctor))
			}
		}
	}
	
	static Func makeCtorInjectionPlan(InjectionCtx ctx, Type building) {
		InjectionCtx.track("Creating injection plan for fields of $building.qname") |->Obj| {
			plan := Field:Obj?[:]
			findFieldsWithFacet(ctx, building, Inject#, true).each |field| {
				InjectionCtx.withFacets(field.facets) |->| {
					dependency := findDependencyByType(ctx, field.type)
					plan[field] = dependency
				}
			}
			if (plan.isEmpty)
				InjectionCtx.log("No injection fields found")
			return Field.makeSetFunc(plan)
		}
	}

	// ---- Private Methods -----------------------------------------------------------------------

	** Calls methods (of all visibilities) that have the @PostInjection facet
	private static Obj callPostInjectMethods(InjectionCtx ctx, Obj object) {
		InjectionCtx.track("Calling post injection methods of $object.typeof.qname") |->Obj| {
			if (!object.typeof.methods
				.findAll |method| {
					method.hasFacet(PostInjection#)
				}
				.reduce(false) |bool, method| {
					InjectionCtx.log("Found method $method.signature")
					callMethod(ctx, method, object, Obj#.emptyList)
					return true
				})
				InjectionCtx.log("No post injection methods found")
			return object
		}
	}

	private static Obj?[] findMethodInjectionParams(InjectionCtx ctx, Method method, Obj?[] providedMethodArgs) {
		return InjectionCtx.track("Determining injection parameters for $method.signature") |->Obj?[]| {
			InjectionCtx.withFacets(Facet[,]) |->Obj?[]| {
				params := method.params.map |param, index| {
					
					InjectionCtx.log("Found parameter ${index+1}) $param.type")
					if (index < providedMethodArgs.size) {
						InjectionCtx.log("Parameter provided")
						
						provided := providedMethodArgs[index] 
						if (provided != null && !provided.typeof.fits(param.type))
							throw IocErr(IocMessages.providerMethodArgDoesNotFit(provided.typeof, param.type))
						return provided
					}
					
					return findDependencyByType(ctx, param.type)
				}		
				if (params.isEmpty)
					InjectionCtx.log("No injection parameters found")
				return params
			}
		}
	}

	private static Obj? findDependencyByType(InjectionCtx ctx, Type dependencyType) {
		InjectionCtx.track("Looking for dependency of type $dependencyType") |->Obj?| {
			InjectionCtx.peek.objLocator.trackDependencyByType(ctx, dependencyType)
		}
	}

	private static Void inject(InjectionCtx ctx, Obj target, Field field, Obj? value) {
		InjectionCtx.track("Injecting ${value?.typeof?.qname} into field $field.signature") |->| {
			if (field.get(target) != null) {
				InjectionCtx.log("Field has non null value. Aborting injection.")
				return
			}
			// BugFix: if injecting null (via DepProvider) then don't throw the Const Err below
			if (value == null)
				return	
			if (field.isConst)
				throw IocErr(IocMessages.cannotSetConstFields(field))
			field.set(target, value)
		}
	}

	private static Method[] findConstructors(Type type) { 
		type.methods.findAll |method| { method.isCtor && method.parent == type }
	}

	private static Field[] findFieldsWithFacet(InjectionCtx ctx, Type type, Type facetType, Bool includeConst) {
		type.fields.findAll |field| {
			// Ignore all static and final fields.
	    	if (field.isStatic)
	    		return false
			
			if (field.isConst && !includeConst)
				return false

	    	if (!field.hasFacet(facetType)) 
	    		return false

    		InjectionCtx.log("Found field $field.signature")
			return true
		}
	}
}
