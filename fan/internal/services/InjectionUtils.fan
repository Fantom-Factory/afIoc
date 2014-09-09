using afBeanUtils

internal const class InjectionUtils {

	private const ObjLocator objLocator
	
	new make(ObjLocator objLocator) {
		this.objLocator = objLocator 
	}
	
	** Injects into the fields (of all visibilities) where the @Inject facet is present.
	Obj injectIntoFields(Obj object) {
		track("Injecting dependencies into fields of $object.typeof.qname") |->| {
			if (!findInjectableFields(object.typeof, true)
				.reduce(false) |bool, field| {
					InjectionTracker.doingFieldInjection(object, field) |->Bool| {
						dependency := findDependencyFromInjectFacet(field)
						if (dependency != null)
							inject(object, field, dependency)
						return true
					}
				})
				log("No injection fields found")
		}

		callPostInjectMethods(object)
		return object
	}

	Obj? callMethod(Method method, Obj? obj, Obj?[]? providedMethodArgs) {
		InjectionTracker.doingMethodInjection(obj, method) |->Obj?| {
			args := findMethodInjectionParams(method, providedMethodArgs)
			return track("Invoking $method.signature on ${method.parent}...") |->Obj?| {
				return (obj == null) ? method.callList(args) : method.callOn(obj, args)
			}
		}
	}

	** A return value of 'null' signifies the type has no ctors and must be instantiated via `Type.make`
	static Method? findAutobuildConstructor(Type type) {
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
	}

	Obj createViaConstructor(Method? ctor, Obj?[]? providedCtorArgs, [Field:Obj?]? fieldVals) {
		building := ctor.parent
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
				throw IocErr(IocMessages.fieldNotSetErr(e.msg, ctor), e)
			}
		}
	}

	Func makeCtorInjectionPlan(Type building) {
		track("Creating injection plan for fields of $building.qname") |->Obj| {
			plan := Field:Obj?[:]
			findInjectableFields(building, true).each |field| {
				InjectionTracker.doingFieldInjectionViaItBlock(building, field) |->| {
					dependency := findDependencyFromInjectFacet(field)
					if (dependency != null)
						plan[field] = dependency
				}
			}
			ctorFieldVals := InjectionTracker.injectionCtx.ctorFieldVals 
			if (ctorFieldVals != null) {
				ctorFieldVals = ctorFieldVals.map |val, field| {
					if (!building.fits(field.parent))
						throw IocErr(IocMessages.injectionUtils_ctorFieldType_wrongType(field, building))
					if (val == null && !field.type.isNullable)
						throw IocErr(IocMessages.injectionUtils_ctorFieldType_nullValue(field))
					if (val != null && !ReflectUtils.fits(val.typeof, field.type))
						throw IocErr(IocMessages.injectionUtils_ctorFieldType_valDoesNotFit(val, field))
					
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
	private Obj callPostInjectMethods(Obj object) {
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

	private Obj?[] findMethodInjectionParams(Method method, Obj?[]? providedMethodArgs) {
		return track("Determining injection parameters for ${method.parent.qname} $method.signature") |->Obj?[]| {
			params := method.params.map |param, index| {
				log("Parameter ${index+1} = $param.type")

				if ((index) < (providedMethodArgs?.size ?: 0)) {
					log("Parameter provided by user")
					
					provided := providedMethodArgs[index]
					
					if (provided == null && !param.type.isNullable)
						throw IocErr(IocMessages.providerMethodArgDoesNotFit(null, param.type))
					if (provided != null && !ReflectUtils.fits(provided.typeof, param.type))
						throw IocErr(IocMessages.providerMethodArgDoesNotFit(provided.typeof, param.type))

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

	private Obj? findDependencyFromInjectFacet(Field field) {
		inject := (Inject) Slot#.method("facet").callOn(field, [Inject#])	// Stoopid F4

		if (inject.serviceId != null) {
			log("Field has @Inject { serviceId='${inject.serviceId}' }")

			service := objLocator.trackServiceById(inject.serviceId, !inject.optional)
			if (service == null && inject.optional) {
				log("Field has @Inject { optional=true }")
				log("Service not found - failing silently...")
				return null
			}			
			
			if (!service.typeof.fits(field.type))
				throw IocErr(IocMessages.serviceIdDoesNotFit(inject.serviceId, service.typeof, field.type))
			return service
		}

		dependency := findDependencyByType(field.type, !inject.optional)
		if (dependency == null && inject.optional) {
			log("Field has @Inject { optional=true }")
			log("Dependency not found - failing silently...")
		}
		return dependency
	}
	
	private Obj? findDependencyByType(Type dependencyType, Bool checked) {
		track("Looking for dependency of type $dependencyType") |->Obj?| {
			objLocator.trackDependencyByType(dependencyType, checked)
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
		// use fits so nullable types == non-nullable types
		type.methods.findAll |method| { method.isCtor && method.parent.fits(type) }
	}

	private static Field[] findInjectableFields(Type type, Bool includeConst) {
		type.fields.findAll |field| {
			if (!field.hasFacet(Inject#) && !field.hasFacet(Autobuild#)) 
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

	static Void log(Str msg) {
		InjectionTracker.log(msg)
	}
}
