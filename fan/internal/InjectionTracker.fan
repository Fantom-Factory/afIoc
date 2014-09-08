using concurrent::Actor

internal class InjectionTracker {

	private static const Str 	trackerId		:= "afIoc.injectionTracker"
	private static const Str 	serviceDefId	:= "afIoc.serviceDef"
	private static const Str 	confProviderId	:= "afIoc.configProvider"
	private static const Str 	injectionCtxId	:= "afIoc.injectionCtx"
	
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
		ThreadStack.pushAndRun(serviceDefId, def) |->Obj?| {
			// check for recursion
			ThreadStack.elements(serviceDefId).eachRange(0..<-1) |ServiceDef ele| { 
				if (ele.serviceId == def.serviceId)
					throw IocErr(IocMessages.serviceRecursion(ThreadStack.elements(serviceDefId).map |ServiceDef sd->Str| { sd.serviceId }))
			}

			return operation.call()
		}
	}

	// ---- Config Providing -------------------------------------------------------------------------------------------

	static Obj? withConfigProvider(ConfigProvider provider, |->Obj?| operation) {
		ThreadStack.pushAndRun(confProviderId, provider, operation)
	}

	static Bool canProvideConfig(Type dependencyType) {
		ctx := (ConfigProvider?) ThreadStack.peek(confProviderId, false)
		return ctx != null && ctx.canProvide(dependencyType)
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
		ctx := InjectionCtx(InjectionKind.dependencyByType) {
			it.dependencyType = dependencyType
		}
		return ThreadStack.pushAndRun(injectionCtxId, ctx, func)
	}
	
	static Obj? doingFieldInjection(Obj injectingInto, Field field, |->Obj?| func) {
		ctx := InjectionCtx(InjectionKind.fieldInjection) {
			it.injectingInto	= injectingInto
			it.injectingIntoType= injectingInto.typeof
			it.dependencyType	= field.type
			it.field			= field
			it.fieldFacets		= field.facets
		}
		return ThreadStack.pushAndRun(injectionCtxId, ctx, func)
	}

	static Obj? doingFieldInjectionViaItBlock(Type injectingIntoType, Field field, |->Obj?| func) {
		ctx := InjectionCtx(InjectionKind.fieldInjection) {
			it.injectingIntoType= injectingIntoType
			it.dependencyType	= field.type
			it.field			= field
			it.fieldFacets		= field.facets
		}
		return ThreadStack.pushAndRun(injectionCtxId, ctx, func)
	}

	static Obj? doingMethodInjection(Obj? injectingInto, Method method, |->Obj?| func) {
		ctx := InjectionCtx(InjectionKind.methodInjection) {
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
		ctx := InjectionCtx(InjectionKind.methodInjection) {
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
		ctx.dependencyType		= param.type
		ctx.methodParam			= param
		ctx.methodParamIndex	= index
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
