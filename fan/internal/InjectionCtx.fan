using concurrent::Actor

internal class InjectionCtx {

	static const Str 			injectionCtxId	:= "afIoc.injectionCtx"
	static const Str 			serviceDefId	:= "afIoc.serviceDef"
	static const Str 			confProviderId	:= "afIoc.configProvider"
	static const Str 			injectCtxId		:= "afIoc.injectCtx"
	
	private Facet[][]			facetsStack	:= [,]
	OpTracker 					tracker
	ObjLocator? 				objLocator

	** for testing only
	new make(ObjLocator? objLocator, OpTracker tracker := OpTracker()) {
		this.objLocator = objLocator
		this.tracker	= tracker
	}

	static Void forTesting_push(InjectionCtx ctx) {
		ThreadStack.forTesting_push(injectionCtxId, ctx)
	}

	static Void forTesting_clear() {
		ThreadStack.forTesting_clear(injectionCtxId)
	}

	static Obj? withCtx(ObjLocator? objLocator, OpTracker? tracker, |->Obj?| f) {
		ctx := peek(false) ?: InjectionCtx.make(objLocator, tracker ?: OpTracker())
		// all the objs on the stack should be the same instance - this doesn't *need* to be a stack
		return ThreadStack.pushAndRun(injectionCtxId, ctx, f)
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

	** Only used for detecting recursion 
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
		// TODO:
		ctx := InjectCtx(InjectionType.dependencyByType) {
			it.dependencyType = dependencyType
		}
		return ThreadStack.pushAndRun(injectCtxId, ctx, func)
	}
	
	static Obj? injectingField(Type injectingInto, Field field, |->Obj?| func) {
		// TODO:
		ctx := InjectCtx(InjectionType.fieldInjection) {
			it.injectingInto	= injectingInto
			it.dependencyType	= field.type
			it.field			= field
			it.fieldFacets		= field.facets
		}
		return ThreadStack.pushAndRun(injectCtxId, ctx, func)
	}

	static Obj? injectingFieldViaItBlock(Type injectingInto, Field field, |->Obj?| func) {
		// TODO:
		ctx := InjectCtx(InjectionType.fieldInjection) {
			it.injectingInto	= injectingInto
			it.dependencyType	= field.type
			it.field			= field
			it.fieldFacets		= field.facets
		}
		return ThreadStack.pushAndRun(injectCtxId, ctx, func)
	}

	static Obj? injectingMethod(Type injectingInto, Method method, |->Obj?| func) {
		// TODO:
		ctx := InjectCtx(InjectionType.methodInjection) {
			it.injectingInto	= injectingInto
			it.method			= method
			it.methodFacets		= method.facets		
		}
		return ThreadStack.pushAndRun(injectCtxId, ctx, func)
	}

	static Obj? injectingCtor(Type injectingInto, Method ctor, |->Obj?| func) {
		// TODO:
		ctx := InjectCtx(InjectionType.methodInjection) {
			it.injectingInto	= injectingInto
			it.method			= ctor
			it.methodFacets		= ctor.facets
		}
		return ThreadStack.pushAndRun(injectCtxId, ctx, func)
	}

	static Obj? injectingParam(Param param, Int index, |->Obj?| func) {
		// TODO:
		ctx := (InjectCtx) ThreadStack.peek(injectCtxId)
		ctx.dependencyType		= param.type
		ctx.methodParam			= param
		ctx.methodParamIndex	= index
		return func.call
	}


	
	
	// TODO: this could be CtxObj with all you uneed
	@Deprecated
	static ServiceDef? building() {
		def := (ServiceDef?) ThreadStack.peek(serviceDefId, false)
		if (def?.scope == ServiceScope.perInjection)
			def = ThreadStack.peekParent(serviceDefId, false)
		return def
	}


	// ----

	@Deprecated
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
		ThreadStack.peek(injectionCtxId, checked)
	}
}

internal class InjectCtx {
	
	InjectionType 	injectionType
	Type?			injectingInto
	Type?			dependencyType

	Field?			field
	Facet[]?		fieldFacets

	Method?			method
	Facet[]?		methodFacets
	Param?			methodParam
	Int?			methodParamIndex
	
	new make(InjectionType injectionType, |This|? in := null) {
		in?.call(this)
		this.injectionType = injectionType
	}
}

enum class InjectionType {
	dependencyByType,
	fieldInjection,
	fieldInjectionViaItBlock,
	ctorInjection,
	methodInjection;	
}