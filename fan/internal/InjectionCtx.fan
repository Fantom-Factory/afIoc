using concurrent::Actor

internal class InjectionCtx {

	static const Str 			stackId		:= "afIoc.injectionCtx"
	
//	static const Str 			ctxKey			:= "afIoc.injectionCtx"		
//	static const Str 			cntKey			:= "afIoc.injectionCtx.count"		
	private ServiceDef[]		defStack	:= [,]
	private ConfigProvider[]	configStack	:= [,]
	private Facet[][]			facetsStack	:= [,]
	OpTracker 					tracker
	ObjLocator? 				objLocator

	** for testing only
	new make(ObjLocator? objLocator, OpTracker tracker := OpTracker()) {
		this.objLocator = objLocator
		this.tracker	= tracker
	}

	static Void forTesting_push(InjectionCtx ctx) {
		ThreadStack.forTesting_push(stackId, ctx)
	}

	static Void forTesting_clear() {
		ThreadStack.forTesting_clear(stackId)
	}

	static Obj? withCtx(ObjLocator? objLocator, OpTracker? tracker, |InjectionCtx ctx->Obj?| f) {
		ctx := peek(false) ?: InjectionCtx.make(objLocator, tracker ?: OpTracker())
		// all the objs on the stack should be the same
		return ThreadStack.pushAndRun(stackId, ctx, f)
	}

	static Obj? track(Str description, |->Obj?| operation) {
		peek.tracker.track(description, operation)
	}

	static Void logExpensive(|->Str| msg) {
		peek.tracker.logExpensive(msg)
	}

	static Void log(Str description) {
		peek.tracker.log(description)
	}

	static Obj? withServiceDef(ServiceDef def, |->Obj?| operation) {
		ctx := peek
		// check for allowed scope
		if (ctx.defStack.peek?.scope == ServiceScope.perApplication && def.scope == ServiceScope.perThread)
			if (!def.proxiable)
				throw IocErr(IocMessages.threadScopeInAppScope(ctx.defStack.peek.serviceId, def.serviceId))

		ctx.defStack.push(def)

		try {
			// check for recursion
			ctx.defStack[0..<-1].each { 
				// the servicedef may be the same, but if the scope is perInjection, the instances will be different
				if (it.serviceId == def.serviceId && def.scope != ServiceScope.perInjection)
					throw IocErr(IocMessages.serviceRecursion(ctx.defStack.map { it.serviceId }))
			}

			return operation.call()

		} finally {
			ctx.defStack.pop
		}
	}

	static Obj? withProvider(ConfigProvider provider, |->Obj?| operation) {
		ctx := peek
		ctx.configStack.push(provider)
		try {
			return operation.call()
		} finally {			
			ctx.configStack.pop
		}
	}

	static Obj? withFacets(Facet[] facets, |->Obj?| operation) {
		ctx := peek
		ctx.facetsStack.push(facets)
		try {
			return operation.call()
		} finally {			
			ctx.facetsStack.pop
		}
	}

	static ServiceDef? building() {
		ctx := peek
		def := ctx.defStack.peek
		if (def?.scope == ServiceScope.perInjection)
			def = ctx.defStack[-2]
		return def
	}

	static Obj? provideConfig(Type dependencyType) {
		ctx := peek
		// jus' passin' thru!
		if (ctx.configStack.peek?.canProvide(providerCtx, dependencyType) ?: false)
			return ctx.configStack.peek.provide(providerCtx, dependencyType)
		return null
	}
	
	static ProviderCtx providerCtx() {
		ctx := peek
		return ProviderCtx {
			it.injectionCtx 	= ctx
			it.facets			= ctx.facetsStack.peek ?: Facet#.emptyList
		}
	}
	
	static InjectionCtx? peek(Bool checked := true) {
		ThreadStack.peek(stackId, checked)
	}
}
