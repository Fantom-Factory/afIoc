using concurrent::Actor

// static methods only
internal mixin InjectionTracker {

	static const Str 	trackerId		:= "afIoc.injectionTracker"
	static const Str 	serviceDefId	:= "afIoc.serviceDef"
	static const Str 	confProviderId	:= "afIoc.configProvider"
	static const Str 	injectionCtxId	:= "afIoc.injectionCtx"
	
	static Obj? withCtx(OpTracker tracker, |->Obj?| f) {
		ThreadStack.pushAndRun(trackerId, tracker, f)
	}

	static Obj? track(Str description, |->Obj?| operation) {
		if (ThreadStack.peek(trackerId, false) == null) {
			
			// hand code pushAndRun to cut down on some call stack
			threadStack	:= ThreadStack.getOrMakeStack(trackerId)
			threadStack.stack.push(OpTracker())
			try {
				return tracker.track(description, operation)
				
			} finally {
				threadStack.stack.pop
				if (threadStack.stack.isEmpty)
					Actor.locals.remove(trackerId)			
			}
			
		} else
			return tracker.track(description, operation)
	}

	static Void log(Str msg) {
		tracker.log(msg)
	}

	private static OpTracker tracker() {
		ThreadStack.peek(trackerId, true)
	}

	// ---- Recursion Detection ----------------------------------------------------------------------------------------

	static Obj? recursionCheck(ServiceDef def, Str msg, |->Obj?| operation) {
		threadStack := ThreadStack.getOrMakeStack(serviceDefId)

		// check for recursion
		ThreadStack.elements(serviceDefId).each |ServiceDef ele| { 
			if (ele.serviceId == def.serviceId)
				throw IocErr(IocMessages.serviceRecursion(ThreadStack.elements(serviceDefId).dup.add(def).map |ServiceDef sd->Str| { sd.serviceId }))
		}
		
		// hand code pushAndRun to cut down on some call stack
		threadStack.stack.push(def)
		try {
			return track(msg, operation)
		} finally {
			threadStack.stack.pop
			if (threadStack.stack.isEmpty)
				Actor.locals.remove(serviceDefId)			
		}
	}

	static ServiceDef? peekServiceDef() {
		ThreadStack.peek(serviceDefId, false)
	}

	// ---- Injection Ctx ----------------------------------------------------------------------------------------------

	static Obj? doingDependencyByType(Type dependencyType, |InjectionCtx->Obj?| func) {
		ctx := InjectionCtx(InjectionKind.dependencyByType) {
			it.dependencyType = dependencyType
		}
		return ThreadStack.pushAndRun(injectionCtxId, ctx, func)
	}
	
	static Obj? doingFieldInjection(Obj injectingInto, Field field, |InjectionCtx->Obj?| func) {
		ctx := InjectionCtx(InjectionKind.fieldInjection) {
			it.injectingInto	= injectingInto
			it.injectingIntoType= injectingInto.typeof
			it.dependencyType	= field.type
			it.field			= field
			it.fieldFacets		= field.facets
		}
		return ThreadStack.pushAndRun(injectionCtxId, ctx, func)
	}

	static Obj? doingFieldInjectionViaItBlock(Type injectingIntoType, Field field, |InjectionCtx->Obj?| func) {
		ctx := InjectionCtx(InjectionKind.fieldInjectionViaItBlock) {
			it.injectingIntoType= injectingIntoType
			it.dependencyType	= field.type
			it.field			= field
			it.fieldFacets		= field.facets
		}
		return ThreadStack.pushAndRun(injectionCtxId, ctx, func)
	}

	static Obj? doingMethodInjection(Obj? injectingInto, Method method, |InjectionCtx->Obj?| func) {
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

	static Obj? doingCtorInjection(Type injectingIntoType, Method ctor, [Field:Obj?]? fieldVals, |InjectionCtx->Obj?| func) {
		ctx := InjectionCtx(InjectionKind.ctorInjection) {
			it.injectingIntoType= injectingIntoType
			it.method			= ctor
			it.methodFacets		= ctor.facets
			it.ctorFieldVals	= fieldVals
			// this will get replaced with the param value
			it.dependencyType	= Void#
		}
		return ThreadStack.pushAndRun(injectionCtxId, ctx, func)
	}

	static Obj? doingParamInjection(InjectionCtx ctx, Param param, Int index, |InjectionCtx->Obj?| func) {
		ctx.dependencyType		= param.type
		ctx.methodParam			= param
		ctx.methodParamIndex	= index
		return func.call(ctx)
	}

	// sigh - this whole injectionCtx stack is only needed for ONE call in ServiceDef.getService()!
	static InjectionCtx injectionCtx() {
		ThreadStack.peek(injectionCtxId)
	}
}
