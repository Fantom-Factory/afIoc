
** Contribute to 'afIoc::AutoBuilderHooks.onBuild' to add funcs that get called whenever a class is autobuilt:
** 
** pre>
** @Contribute{ serviceId="afIoc::AutoBuilderHooks.onBuild" }
** Void cont(Configuration config) {
**     config["me"] = |Scope scope, Obj instance| {
**         ...
**     }
** }
** <pre
@Js @NoDoc	// Advanced use only
const class AutoBuilder {
	private const Log 					log 				:= AutoBuilder#.pod.log
	private const DependencyProviders	dependencyProviders
	private const Unsafe 				buildHooksRef		// 'cos JS has no notion of immutable funcs

	new make(Str:|Scope, Obj| buildHooks, DependencyProviders dependencyProviders) {
		if (Env.cur.runtime != "js")
			buildHooks.each |val, key| {
				try		buildHooks[key] = val.toImmutable
				catch	throw ArgErr(ErrMsgs.autobuilder_funcNotImmutable("afIoc::AutoBuilderHooks.onBuild", key))
			}

		this.dependencyProviders 	= dependencyProviders
		this.buildHooksRef			= Unsafe(buildHooks)
	}
	
	virtual Obj? autobuild(Scope currentScope, Type type, Obj?[]? ctorArgs, [Field:Obj?]? fieldVals, Str? serviceId) {
		
		if (serviceId == null) {
			// we can't easily bring back the serviceDef, 'cos there may be multiple services
			serviceExistsForType := ((ScopeImpl) currentScope).containsServiceType(type)
			if (serviceExistsForType)
				log.warn(ErrMsgs.autobuilder_warnAutobuildingService(type))
		}
		
		impl := findImplType(type, null)
		
		ctor := findConstructor(currentScope, impl, ctorArgs, serviceId)
		
		plan := findFieldVals(currentScope, impl, null, serviceId, fieldVals?.keys)
		fieldVals?.each |val, key| {
			// add and convert provided values
			plan.add(key, key.isConst ? toImmutableObj(key, val) : val)
		}

		inst := null

		if (ctor != null) {
			args := findFuncArgs(currentScope, ctor.func, ctorArgs, null, serviceId)
		
			fieldsFound := plan.keys
			if (ctor.params.last != null && ctor.params.last.type.fits(|This|#)) {
				args[-1] = Field.makeSetFunc(plan.dup)	// don't clear the 'plan' before it's been used!
				plan.clear
			}
			
			inst = ctor.callList(args)
			
			// check if we get any more takers now we have the instance to work with
			if (impl.isConst.not) {
				moar := findFieldVals(currentScope, impl, inst, serviceId, fieldsFound)
				plan.addAll(moar)
			}
			
		} else
			inst = impl.make
		
		// if service has no it-block ctor, throw sys::ReadonlyErr: Cannot set const field
		// it's actually the most understandable Err! 
//		if (impl.isConst.not)
			plan.each |val, field| {
				field.set(inst, val)
			}

		callPostInjectionMethods(currentScope, serviceId, inst, impl)
		
		buildHooks := (Str:|Scope, Obj->Obj?|) buildHooksRef.val
		// call with scope first so it matches onServiceBuild and other methods
		buildHooks.each {
			newVal := it.call(currentScope, inst)
			
			// allow our new instance to be re-assigned / decorated
			if (it.returns != Void#)
				inst = newVal
		}
		
		return inst
	}
	
	@NoDoc
	virtual Void callPostInjectionMethods(Scope currentScope, Str? serviceId, Obj inst, Type impl) {
		impl.methods.findAll { it.hasFacet(PostInjection#) }.each |method| {
			methodArgs := findFuncArgs(currentScope, method.func, null, inst, serviceId)
			method.callOn(inst, methodArgs)
		}		
	}
	
	** A return value of 'null' signifies the type has no ctors and must be instantiated via `Type.make`
	virtual Method? findConstructor(Scope currentScope, Type implType, Obj?[]? ctorArgs, Str? serviceId) {

		// use fits so nullable types == non-nullable types
		constructors := implType.methods.findAll |method| { method.isCtor && method.parent.fits(implType) }

		// if no ctors, use Type.make()
		if (constructors.isEmpty)
			return null

		// return the @Inject annotated ctor
		annotated := constructors.findAll |c| { c.hasFacet(Inject#) }
		if (annotated.size == 1)
			return annotated[0]
				
		// find the best fitting ctors
		potential := annotated.size > 1 ? annotated : constructors
		ctors := potential.findAll |ctor| {
			injectCtx := InjectionCtxImpl {
				it.serviceId	= serviceId
				it.targetType	= implType
				it.func			= ctor.func
				it.funcArgs		= ctorArgs
			}
			
			usingDefs := false
			return ctor.params.all |param, idx| {
				if (usingDefs) return true

				injectCtx.funcParam 		= param
				injectCtx.funcParamIndex	= idx
				canProvide := dependencyProviders.canProvide(currentScope, injectCtx)
				
				// default vals trump optional / nullable values
				if (!canProvide && param.hasDefault) {
					usingDefs = true
					return true
				}

				if (!canProvide && param.type.isNullable)
					return true

				return canProvide
			}
		}

		if (ctors.isEmpty)
			throw IocErr(ErrMsgs.autobuilder_couldNotFindAutobuildCtor(implType, ctorArgs?.map |Obj? arg->Type?| { arg?.typeof }))
		
		// there can be only one!
		if (ctors.size == 1)
			return ctors.first
		
		// choose the ctor with the most parameters
		params := ctors.sortr |c1, c2| {
			c1.params.size <=> c2.params.size
		}

		if (params[0].params.size == params[1].params.size)
			throw IocErr(ErrMsgs.autobuilder_ctorsWithSameNoOfParams(implType, params[1].params.size))				

		return params.first
	}

	virtual Obj?[] findFuncArgs(Scope currentScope, Func func, Obj?[]? args, Obj? instance, Str? serviceId) {
		injectCtx := InjectionCtxImpl {
			it.serviceId		= serviceId
			it.targetType		= func.method?.parent
			it.targetInstance	= instance
			it.func				= func
			it.funcArgs			= args
		}
		
		return dependencyProviders.provideFuncParams(currentScope, injectCtx)
	}
	
	virtual Field:Obj? findFieldVals(Scope currentScope, Type type, Obj? instance, Str? serviceId, Field[]? ignore) {
		injectCtx := InjectionCtxImpl {
			it.serviceId		= serviceId
			it.targetType		= type
			it.targetInstance	= instance
		}
		
		fieldVals := Field:Obj?[:]
		
		// see Dissapearing Private Fields - http://fantom.org/forum/topic/2383
		fields := type.inheritance.map { it.fields }.flatten.unique.removeAll(ignore ?: Field#.emptyList)
		fields.each |Field field| {
			injectCtx.field	= field
			dependencyProviders.provideFieldValue(currentScope, injectCtx, fieldVals)
		}
		return fieldVals
	}
	
	virtual Type? findImplType(Type serviceType, Type? serviceImplType) {
		
		if (serviceImplType == null)
			if (serviceType.isAbstract || serviceType.isMixin) {
				expectedImplName 	:= serviceType.qname + "Impl"
				serviceImplType		= Type.find(expectedImplName, false)
				if (serviceImplType == null)
					throw IocErr(ErrMsgs.autobuilder_couldNotFindImplType(serviceType))
			} else
				serviceImplType = serviceType

		if (serviceImplType.isMixin) 
			throw IocErr(ErrMsgs.autobuilder_bindImplNotClass(serviceImplType))

		if (!serviceImplType.fits(serviceType))
			throw IocErr(ErrMsgs.autobuilder_bindImplDoesNotFit(serviceType, serviceImplType))

		return serviceImplType
	}
	
	private static Obj? toImmutableObj(Field key, Obj? obj) {
		if (obj is Func && Env.cur.runtime == "js")
			throw Err("Immutable funcs are not available in Javascript: ${key.qname}\nSee http://fantom.org/forum/topic/114 for details.")
		return obj?.toImmutable
	}
}
