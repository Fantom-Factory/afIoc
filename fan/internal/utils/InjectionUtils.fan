
internal const class InjectionUtils {

	static Obj autobuild(Type type, Obj?[] ctorArgs) {
		track("Autobuilding $type.qname") |->Obj| {
			ctor := findAutobuildConstructor(type)
			obj  := createViaConstructor(ctor, type, ctorArgs)
			injectIntoFields(obj)
			return obj
		}
	}

	** Injects into the fields (of all visibilities) where the @Inject facet is present.
	static Obj injectIntoFields(Obj object) {
		track("Injecting dependencies into fields of $object.typeof.qname") |->| {
			if (!findFieldsWithFacet(object.typeof, Inject#, true)
				.reduce(false) |bool, field| {
					InjectionCtx.injectingField(object.typeof, field) |->Bool| {
						InjectionCtx.withFacets(field.facets) |->Bool| {
							dependency := findDependencyByType(field.type)
							inject(object, field, dependency)
							return true
						}
					}
				})
				log("No injection fields found")
		}

		callPostInjectMethods(object)
		return object
	}

	static Obj? callMethod(Method method, Obj? obj, Obj?[] providedMethodArgs) {
		InjectionCtx.injectingMethod(method.parent, method) |->Obj?| {
			args := findMethodInjectionParams(method, providedMethodArgs)
			return track("Invoking $method.signature on ${method.parent}...") |->Obj?| {
				return (obj == null) ? method.callList(args) : method.callOn(obj, args)
			}
		}
	}

	** A return value of 'null' signifies the type has no ctors and must be instantiated via `Type.make`
	static Method? findAutobuildConstructor(Type type) {
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
				log("Found ${type.name}()")
			else
				log("Found ${ctor.signature}")
			return ctor
		}
	}

	static Obj createViaConstructor(Method? ctor, Type building, Obj?[] providedCtorArgs) {
		if (ctor == null) {
			return track("Instantiating $building via ${building.name}()...") |->Obj| {
				return building.make()
			}
		}
		
		args := InjectionCtx.injectingCtor(building, ctor) |->Obj?| {
			return findMethodInjectionParams(ctor, providedCtorArgs)
		}
		
		return track("Instantiating $building via ${ctor.signature}...") |->Obj| {
			try {
				return ctor.callList(args)
			
			// this is such a common err, we treat it as our own to remove Ioc stack frames
			} catch (FieldNotSetErr e) {
				throw IocErr(IocMessages.fieldNotSetErr(e.msg, ctor))
			}
		}
	}

	static Func makeCtorInjectionPlan(Type building) {
		track("Creating injection plan for fields of $building.qname") |->Obj| {
			plan := Field:Obj?[:]
			findFieldsWithFacet(building, Inject#, true).each |field| {
				InjectionCtx.injectingFieldViaItBlock(building, field) |->| {
					InjectionCtx.withFacets(field.facets) |->| {
						dependency := findDependencyByType(field.type)
						plan[field] = dependency
					}
				}
			}
			if (plan.isEmpty)
				log("No injection fields found")
			return Field.makeSetFunc(plan)
		}
	}

	// ---- Private Methods -----------------------------------------------------------------------

	** Calls methods (of all visibilities) that have the @PostInjection facet
	private static Obj callPostInjectMethods(Obj object) {
		track("Calling post injection methods of $object.typeof.qname") |->Obj| {
			if (!object.typeof.methods
				.findAll |method| {
					method.hasFacet(PostInjection#)
				}
				.reduce(false) |bool, method| {
					log("Found method $method.signature")
					callMethod(method, object, Obj#.emptyList)
					return true
				})
				log("No post injection methods found")
			return object
		}
	}

	private static Obj?[] findMethodInjectionParams(Method method, Obj?[] providedMethodArgs) {
		return track("Determining injection parameters for $method.signature") |->Obj?[]| {
			InjectionCtx.withFacets(Facet#.emptyList) |->Obj?[]| {
				params := method.params.map |param, index| {
					
					log("Found parameter ${index+1}) $param.type")
					if (index < providedMethodArgs.size) {
						log("Parameter provided")
						
						provided := providedMethodArgs[index] 
						if (provided != null && !provided.typeof.fits(param.type))
							throw IocErr(IocMessages.providerMethodArgDoesNotFit(provided.typeof, param.type))
						return provided
					}
					
					return InjectionCtx.injectingParam(param, index) |->Obj?| {
						return findDependencyByType(param.type)
					}
				}		
				if (params.isEmpty)
					log("No injection parameters found")
				return params
			}
		}
	}

	private static Obj? findDependencyByType(Type dependencyType) {
		track("Looking for dependency of type $dependencyType") |->Obj?| {
			InjectionCtx.peek.objLocator.trackDependencyByType(dependencyType)
		}
	}

	private static Void inject(Obj target, Field field, Obj? value) {
		track("Injecting ${value?.typeof?.qname} into field $field.signature") |->| {
			if (field.get(target) != null) {
				log("Field has non null value. Aborting injection.")
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

	private static Field[] findFieldsWithFacet(Type type, Type facetType, Bool includeConst) {
		type.fields.findAll |field| {
			// Ignore all static and final fields.
	    	if (field.isStatic)
	    		return false
			
			if (field.isConst && !includeConst)
				return false

	    	if (!field.hasFacet(facetType)) 
	    		return false

    		log("Found field $field.signature")
			return true
		}
	}

	static Obj? track(Str description, |->Obj?| operation) {
		InjectionCtx.track(description, operation)
	}

	static Void logExpensive(|->Str| msg) {
		InjectionCtx.logExpensive(msg)
	}

	static Void log(Str msg) {
		InjectionCtx.log(msg)
	}
}
