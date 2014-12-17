using afBeanUtils

internal const class InjectionUtils {
	private static const Log logger := Utils.getLog(InjectionUtils#)
	private const ObjLocator objLocator
	
	new make(ObjLocator objLocator) {
		this.objLocator = objLocator 
	}
	
	** Injects dependencies into fields (of all visibilities) 
	Obj injectIntoFields(Obj object) {
		track("Injecting dependencies into fields of $object.typeof.qname") |->| {
			fields := findInjectableFields(object.typeof, true)
			fields.each |field| {
				InjectionTracker.doingFieldInjection(object, field) |ctx->Obj?| {
					dependency := dependencyProviders.provideDependency(ctx, false)
					if (dependency != null)
						inject(object, field, dependency)
					return null
				}
			}
			if (fields.isEmpty)
				log("No injection fields found")
		}

		callPostInjectMethods(object)
		return object
	}

	Obj? callMethod(Method method, Obj? obj, Obj?[]? providedMethodArgs) {
		InjectionTracker.doingMethodInjection(obj, method) |ctx->Obj?| {
			args := findMethodInjectionParams(ctx, method, providedMethodArgs)
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

		args := InjectionTracker.doingCtorInjection(building, ctor, fieldVals) |ctx->Obj?| {
			return findMethodInjectionParams(ctx, ctor, providedCtorArgs)
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

	Func makeCtorInjectionPlan(InjectionCtx ctx) {
		track("Creating injection plan for fields of ${ctx.injectingIntoType.qname}") |->Obj| {
			building := ctx.injectingIntoType
			plan := Field:Obj?[:]
			findInjectableFields(building, true).each |field| {
				InjectionTracker.doingFieldInjectionViaItBlock(building, field) |ctxNew->Obj?| {
					dependency := dependencyProviders.provideDependency(ctxNew, false)
					if (dependency != null)
						plan[field] = dependency
					return null
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

	private Obj?[] findMethodInjectionParams(InjectionCtx ctx, Method method, Obj?[]? providedMethodArgs) {
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

				return InjectionTracker.doingParamInjection(ctx, param, index) |ctxNew->Obj?| {
					dep := dependencyProviders.provideDependency(ctxNew, false)
					// TODO: distinguish between returning null and not providing 
					if (dep != null)
						return dep
					if (param.hasDefault)
						return "afIoc.exclude.me.please!"
					// FIXME: null may be allowed / have been provided
					throw IocErr(IocMessages.noDependencyMatchesType(param.type))
				}
			}.exclude { it == "afIoc.exclude.me.please!" }
			
			if (params.isEmpty)
				log("No injection parameters found")
			return params
		}
	}

	private static Void inject(Obj target, Field field, Obj? value) {
		track("Injecting ${value?.typeof?.qname} into field $field.signature") |->| {
			try {
				if (field.get(target) != null) {
					log("Field has non null value. Aborting injection.")
					return
				}
			} catch (Err err) {
				// be lenient on write-only fields
				logger.warn(IocMessages.injectionUtils_couldNotReadField(field, err.msg))
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
			if (field.isStatic)
				return false

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
	
	// needs to be dynamic 'cos the instance changes during the Registry's ctor
	private DependencyProviders dependencyProviders() {
		this.objLocator.dependencyProviders
	}
}
