using concurrent::Actor

internal class InjectionTracker {

	static const Str 			trackerId		:= "afIoc.injectionTracker"
	static const Str 			serviceDefId	:= "afIoc.serviceDef"
	static const Str 			confProviderId	:= "afIoc.configProvider"
	static const Str 			injectionCtxId	:= "afIoc.injectionCtx"
	
	private OpTracker 			tracker
			ObjLocator?			objLocator

	** nullable & internal for testing only
	new make(ObjLocator? objLocator, OpTracker tracker := OpTracker()) {
		this.objLocator = objLocator
		this.tracker	= tracker
	}

	static Void forTesting_push(InjectionTracker ctx) {
		ThreadStack.forTesting_push(trackerId, ctx)
	}

	static Void forTesting_clear() {
		ThreadStack.forTesting_clear(trackerId)
	}

	static Obj? withCtx(ObjLocator objLocator, OpTracker? tracker, |->Obj?| f) {
		ctx := peek(false) ?: InjectionTracker.make(objLocator, tracker ?: OpTracker())
		// all the objs on the stack should be the same instance - this doesn't *need* to be a stack
		return ThreadStack.pushAndRun(trackerId, ctx, f)
	}

	static Obj? track(Str description, |->Obj?| operation) {
		peek.tracker.track(description, operation)
	}

	static Void log(Str msg) {
		peek.tracker.log(msg)
	}

	static Void logExpensive(|->Str| msgFunc) {
		peek.tracker.logExpensive(msgFunc)
	}

	// ---- Recursion Detection ----------------------------------------------------------------------------------------

	static Obj? withServiceDef(ServiceDef def, |->Obj?| operation) {
		lastDef := (ServiceDef?) ThreadStack.peek(serviceDefId, false)

		// check for allowed scope
		if (lastDef?.scope == ServiceScope.perApplication && def.scope == ServiceScope.perThread)
			if (!def.proxiable && injectionCtx.injectionType.isFieldInjection)
				throw IocErr(IocMessages.threadScopeInAppScope(lastDef.serviceId, def.serviceId))

		return ThreadStack.pushAndRun(serviceDefId, def) |->Obj?| {
			// check for recursion
			ThreadStack.elements(serviceDefId)[0..<-1].each |ServiceDef ele| { 
				// the serviceDef may be the same, but if the scope is perInjection, the instances will be different
				if (ele.serviceId == def.serviceId && def.scope != ServiceScope.perInjection)
					throw IocErr(IocMessages.serviceRecursion(ThreadStack.elements(serviceDefId).map |ServiceDef sd->Str| { sd.serviceId }))
			}

			return operation.call()			
		}
	}

	static ServiceDef? building() {
		def := (ServiceDef?) ThreadStack.peek(serviceDefId, false)
		if (def?.scope == ServiceScope.perInjection)
			def = ThreadStack.peekParent(serviceDefId, false)
		return def
	}

	// ---- Config Providing -------------------------------------------------------------------------------------------

	static Obj? withConfigProvider(ConfigProvider provider, |->Obj?| operation) {
		ThreadStack.pushAndRun(confProviderId, provider, operation)
	}

	static Obj? provideConfig(Type dependencyType) {
		ctx := (ConfigProvider?) ThreadStack.peek(confProviderId, false)
		// jus' passin' thru!
		if (ctx?.canProvide(dependencyType) ?: false)
			return ctx.provide(dependencyType)
		return null
	}

	// ---- Injection Ctx ----------------------------------------------------------------------------------------------

	static Obj? doingDependencyByType(Type dependencyType, |->Obj?| func) {
		ctx := InjectionCtx(InjectionType.dependencyByType) {
			it.dependencyType = dependencyType
		}
		return ThreadStack.pushAndRun(injectionCtxId, ctx, func)
	}
	
	static Obj? doingFieldInjection(Obj injectingInto, Field field, |->Obj?| func) {
		ctx := InjectionCtx(InjectionType.fieldInjection) {
			it.injectingInto	= injectingInto
			it.injectingIntoType= injectingInto.typeof
			it.dependencyType	= field.type
			it.field			= field
			it.fieldFacets		= field.facets
		}
		return ThreadStack.pushAndRun(injectionCtxId, ctx, func)
	}

	static Obj? doingFieldInjectionViaItBlock(Type injectingIntoType, Field field, |->Obj?| func) {
		ctx := InjectionCtx(InjectionType.fieldInjection) {
			it.injectingIntoType= injectingIntoType
			it.dependencyType	= field.type
			it.field			= field
			it.fieldFacets		= field.facets
		}
		return ThreadStack.pushAndRun(injectionCtxId, ctx, func)
	}

	static Obj? doingMethodInjection(Obj? injectingInto, Method method, |->Obj?| func) {
		ctx := InjectionCtx(InjectionType.methodInjection) {
			it.injectingInto	= injectingInto
			it.injectingIntoType= method.parent
			it.method			= method
			it.methodFacets		= method.facets
			// this will get replaced with the param value
			it.dependencyType	= Void#
		}
		return ThreadStack.pushAndRun(injectionCtxId, ctx, func)
	}

	static Obj? doingCtorInjection(Type injectingIntoType, Method ctor, [Field:Obj?]? fieldVals, |->Obj?| func) {
		ctx := InjectionCtx(InjectionType.methodInjection) {
			it.injectingIntoType= injectingIntoType
			it.method			= ctor
			it.methodFacets		= ctor.facets
			it.ctorFieldVals	= fieldVals			
			// this will get replaced with the param value
			it.dependencyType	= Void#
		}
		return ThreadStack.pushAndRun(injectionCtxId, ctx, func)
	}

	static Obj? doingParamInjection(Param param, Int index, |->Obj?| func) {
		ctx := (InjectionCtx) ThreadStack.peek(injectionCtxId)
		newCtx := Utils.cloneObj(ctx) {
			it[InjectionCtx#dependencyType]		= param.type
			it[InjectionCtx#methodParam]		= param
			it[InjectionCtx#methodParamIndex]	= index
		}
		ThreadStack.replace(injectionCtxId, newCtx)
		return func.call
	}

	// ----
	
	static InjectionCtx injectionCtx() {
		ThreadStack.peek(injectionCtxId)
	}
	
	static InjectionTracker? peek(Bool checked := true) {
		ThreadStack.peek(trackerId, checked)
	}
}
