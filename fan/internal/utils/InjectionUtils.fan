
internal const class InjectionUtils {

	static Obj autobuild(Type type, Obj?[] ctorArgs, [Field:Obj?]? fieldVals) {
		track("Autobuilding $type.qname") |->Obj| {
			ctor := findAutobuildConstructor(type)
			obj  := createViaConstructor(ctor, type, ctorArgs, fieldVals)
			injectIntoFields(obj)
			return obj
		}
	}

	** Injects into the fields (of all visibilities) where the @Inject facet is present.
	static Obj injectIntoFields(Obj object) {
		track("Injecting dependencies into fields of $object.typeof.qname") |->| {
			if (!findInjectableFields(object.typeof, true)
				.reduce(false) |bool, field| {
					InjectionTracker.doingFieldInjection(object, field) |->Bool| {
						dependency := findDependencyByType(field.type, true)
						inject(object, field, dependency)
						return true
					}
				})
				log("No injection fields found")
		}

		callPostInjectMethods(object)
		return object
	}

	static Obj? callMethod(Method method, Obj? obj, Obj?[] providedMethodArgs) {
		InjectionTracker.doingMethodInjection(obj, method) |->Obj?| {
			args := findMethodInjectionParams(method, providedMethodArgs)
			return track("Invoking $method.signature on ${method.parent}...") |->Obj?| {
				return (obj == null) ? method.callList(args) : method.callOn(obj, args)
			}
		}
	}

	** A return value of 'null' signifies the type has no ctors and must be instantiated via `Type.make`
	static Method? findAutobuildConstructor(Type type) {
		InjectionTracker.track("Looking for suitable ctor to autobiuld $type.qname") |->Method?| {
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

	static Obj createViaConstructor(Method? ctor, Type building, Obj?[] providedCtorArgs, [Field:Obj?]? fieldVals) {
		if (ctor == null) {
			return track("Instantiating $building via ${building.name}()...") |->Obj| {
				return building.make()
			}
		}

		args := InjectionTracker.doingCtorInjection(building, ctor, fieldVals) |->Obj?| {
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
			findInjectableFields(building, true).each |field| {
				InjectionTracker.doingFieldInjectionViaItBlock(building, field) |->| {
					dependency := findDependencyByType(field.type, true)
					plan[field] = dependency
				}
			}
			ctorFieldVals := InjectionTracker.injectCtx.ctorFieldVals 
			if (ctorFieldVals != null) {
				ctorFieldVals = ctorFieldVals.map |val, field| {
					if (!building.fits(field.parent))
						throw IocErr(IocMessages.injectionUtils_ctorFieldType_wrongType(field, building))
					if (val == null) {
						if (!field.type.isNullable)
							throw IocErr(IocMessages.injectionUtils_ctorFieldType_nullValue(field))
					} else {
						// .toNonNullable is a fix for http://fantom.org/sidewalk/topic/2256
						// it doesn't really matter as we've just dealt with null values
						if (!val.typeof.toNonNullable.fits(field.type.toNonNullable))
							throw IocErr(IocMessages.injectionUtils_ctorFieldType_valDoesNotFit(val, field))
					}
					
					// turn Maps and Lists into their immutable counterparts 
					return field.isConst ? val.toImmutable : val
				}
				log("User provided (${ctorFieldVals.size}) ctor field vals")
				plan.setAll(ctorFieldVals)
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
		return track("Determining injection parameters for ${method.parent.qname} $method.signature") |->Obj?[]| {
			params := method.params.map |param, index| {
				
				log("Parameter ${index+1} = $param.type")
				if (index < providedMethodArgs.size) {
					log("Parameter provided by user")
					
					provided := providedMethodArgs[index] 
					if (provided != null) {
						
						// special case for lists - as Str[] does not fit Obj[] 
						if (provided.typeof.name == "List" && param.type.name == "List") {
							// if the list is empty, who cares about the types!?
							if (!(provided as List).isEmpty) {
								providedListType := provided.typeof.params["V"] 
								paramListType	 := param.type.params["V"]
								if (!providedListType.fits(paramListType))
									throw IocErr(IocMessages.providerMethodArgDoesNotFit(providedListType, paramListType))
							}
						} else if (!provided.typeof.fits(param.type)) 
							throw IocErr(IocMessages.providerMethodArgDoesNotFit(provided.typeof, param.type))
					}
					return provided
				}

				return InjectionTracker.doingParamInjection(param, index) |->Obj?| {
					dep := findDependencyByType(param.type, false)
					if (dep != null)
						return dep
					if (param.hasDefault)
						return "afIoc.exclude.me.please!"
					throw IocErr(IocMessages.noDependencyMatchesType(param.type))
				}
			}.exclude { it == "afIoc.exclude.me.please!" }
			
			if (params.isEmpty)
				log("No injection parameters found")
			return params
		}
	}

	private static Obj? findDependencyByType(Type dependencyType, Bool checked) {
		track("Looking for dependency of type $dependencyType") |->Obj?| {
			InjectionTracker.peek.objLocator.trackDependencyByType(dependencyType, checked)
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

	private static Field[] findInjectableFields(Type type, Bool includeConst) {
		type.fields.findAll |field| {
	    	if (!field.hasFacet(Inject#)) 
	    		return false

	    	if (field.isStatic)
	    		throw IocErr(IocMessages.injectionUtils_fieldIsStatic(field))
			
			if (field.isConst && !includeConst)
				return false

    		log("Found field $field.signature")
			return true
		}
	}

	static Obj? track(Str description, |->Obj?| operation) {
		InjectionTracker.track(description, operation)
	}

	static Void logExpensive(|->Str| msg) {
		InjectionTracker.logExpensive(msg)
	}

	static Void log(Str msg) {
		InjectionTracker.log(msg)
	}
}
