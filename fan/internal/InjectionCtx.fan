using concurrent::Actor

internal class InjectionCtx {

	static const Str 			injectCtxId		:= "afIoc.injectionCtx"
	static const Str 			serviceDefId	:= "afIoc.serviceDef"
	
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
		ThreadStack.forTesting_push(injectCtxId, ctx)
	}

	static Void forTesting_clear() {
		ThreadStack.forTesting_clear(injectCtxId)
	}

	static Obj? withCtx(ObjLocator? objLocator, OpTracker? tracker, |->Obj?| f) {
		ctx := peek(false) ?: InjectionCtx.make(objLocator, tracker ?: OpTracker())
		// all the objs on the stack should be the same instance - this doesn't *need* to be a stack
		return ThreadStack.pushAndRun(injectCtxId, ctx, f)
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

	
	// ----
	
	static Obj? withServiceDef(ServiceDef def, |->Obj?| operation) {
		lastDef := (ServiceDef?) ThreadStack.peek(serviceDefId, false)
		
		// check for allowed scope
		if (lastDef?.scope == ServiceScope.perApplication && def.scope == ServiceScope.perThread)
			if (!def.proxiable)
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
	
	// TODO: this could be CtxObj with all you uneed
	static ServiceDef? building() {
		def := (ServiceDef?) ThreadStack.peek(serviceDefId, false)
		if (def?.scope == ServiceScope.perInjection)
			def = ThreadStack.peekParent(serviceDefId, false)
		return def
	}

	// ----

	static Obj? withProvider(ConfigProvider provider, |->Obj?| operation) {
		ctx := peek
		ctx.configStack.push(provider)
		try {
			return operation.call()
		} finally {			
			ctx.configStack.pop
		}
	}

	static Obj? provideConfig(Type dependencyType) {
		ctx := peek
		// jus' passin' thru!
		if (ctx.configStack.peek?.canProvide(providerCtx, dependencyType) ?: false)
			return ctx.configStack.peek.provide(providerCtx, dependencyType)
		return null
	}

	// ----

	static Obj? withFacets(Facet[] facets, |->Obj?| operation) {
		ctx := peek
		ctx.facetsStack.push(facets)
		try {
			return operation.call()
		} finally {			
			ctx.facetsStack.pop
		}
	}
	
	static ProviderCtx providerCtx() {
		return ProviderCtx {
			it.facets = peek.facetsStack.peek ?: Facet#.emptyList
		}
	}
	
	static InjectionCtx? peek(Bool checked := true) {
		ThreadStack.peek(injectCtxId, checked)
	}
}
