using afBeanUtils

internal const class InjectionUtils {
	private static const Log logger := Utils.getLog(InjectionUtils#)
	private const ObjLocator objLocator
	
	new make(ObjLocator objLocator) {
		this.objLocator = objLocator 
	}
	
	** Injects dependencies into fields (of all visibilities) 
	Obj injectIntoFields(Obj target) {
		return InjectionTracker.track("Injecting dependencies into fields of $target.typeof.qname") |->Obj| {
			fields := findInjectableFields(target.typeof).removeAll(InjectionTracker.takenFields)
			fields.each |field| {
				InjectionTracker.doingFieldInjection(target, field) |ctx->Obj?| {
					if (dependencyProviders.canProvideDependency(ctx)) {
						value := dependencyProviders.provideDependency(ctx)
						if (field.isConst) {
							throw IocErr(IocMessages.cannotSetConstFields(field))
						} else 
							field.set(target, value)
					}
					return null
				}
			}
			if (fields.isEmpty)
				log("No injection fields found")
			return target
		}
	}

	Obj? callMethod(Method method, Obj? obj, Obj?[]? providedMethodArgs) {
		InjectionTracker.doingMethodInjection(obj, method) |ctx->Obj?| {
			args := findMethodInjectionParams(ctx, method, providedMethodArgs)
			return InjectionTracker.track("Invoking $method.signature on ${method.parent}...") |->Obj?| {
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
			return InjectionTracker.track("Instantiating $building via ${building.name}()...") |->Obj| {
				return building.make()
			}
		}

		args := InjectionTracker.doingCtorInjection(building, ctor, fieldVals) |ctx->Obj?| {
			return findMethodInjectionParams(ctx, ctor, providedCtorArgs)
		}
		
		return InjectionTracker.track("Instantiating $building via ${ctor.signature}...") |->Obj| {
			try {
				return ctor.callList(args)
			
			// this is such a common err, we treat it as our own to remove Ioc stack frames
			} catch (FieldNotSetErr e) {
				throw IocErr(IocMessages.fieldNotSetErr(e.msg, ctor), e)
			}
		}
	}

	Func makeCtorInjectionPlan(InjectionCtx ctx) {
		return InjectionTracker.track("Creating injection plan for fields of ${ctx.targetType.qname}") |->Obj| {
			dependencyProviders := dependencyProviders
			building := ctx.targetType
			plan := Field:Obj?[:]
			findInjectableFields(building).each |field| {
				InjectionTracker.doingFieldInjectionViaItBlock(building, field) |ctxNew->Obj?| {
					if (dependencyProviders.canProvideDependency(ctxNew)) {
						plan[field] = dependencyProviders.provideDependency(ctxNew)
						InjectionTracker.takenFields.add(field)
					}
					return null
				}
			}
			ctorFieldVals := ctx.ctorFieldVals 
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

	** Calls methods (of all visibilities) that have the @PostInjection facet
	internal Obj callPostInjectMethods(Obj object) {
		return InjectionTracker.track("Calling post injection methods of $object.typeof.qname") |->Obj| {
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

	// ---- Private Methods -----------------------------------------------------------------------

	private Obj?[] findMethodInjectionParams(InjectionCtx ctx, Method method, Obj?[]? providedMethodArgs) {
		return InjectionTracker.track("Determining injection parameters for ${method.parent.qname} $method.signature") |->Obj?[]| {
			dependencyProviders := dependencyProviders
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
					if (!dependencyProviders.canProvideDependency(ctxNew)) {
						if (param.hasDefault)
							return "afIoc.exclude.me.please!"
						throw IocErr(IocMessages.noDependencyMatchesType(param.type))
					}
					return dependencyProviders.provideDependency(ctxNew, true)
				}
			}.exclude { it == "afIoc.exclude.me.please!" }
			
			if (params.isEmpty)
				log("No injection parameters found")
			return params
		}
	}

	private static Method[] findConstructors(Type type) { 
		// use fits so nullable types == non-nullable types
		type.methods.findAll |method| { method.isCtor && method.parent.fits(type) }
	}

	// internal for testing
	internal static Field[] findInjectableFields(Type type) {
		fieldList	:= (Obj[]) type.inheritance.findAll { it.isClass }.reduce([,]) |Obj[] fields, t| { fields.add(t.fields) } 
		fieldsAll	:= (Field[]) fieldList.flatten.unique
		fields		:= fieldsAll.exclude { it.isAbstract || it.isStatic }

		// TODO: it's tricky (not impossible - but too much work for now!) to tell if a field is overridden,
		// so overridden virtual fields appear in the list twice
		
		fields.each { log("Found field $it.signature") }
		return fields
	}

	static Void log(Str msg) {
		InjectionTracker.log(msg)
	}
	
	// needs to be dynamic 'cos the instance changes during the Registry's ctor
	private DependencyProviders dependencyProviders() {
		this.objLocator.dependencyProviders
	}
}
