using concurrent::Actor

internal class InjectionCtx {

	static const Str 			injectionCtxId	:= "afIoc.injectionCtx"
	static const Str 			serviceDefId	:= "afIoc.serviceDef"
	static const Str 			confProviderId	:= "afIoc.configProvider"
	static const Str 			injectCtxId		:= "afIoc.injectCtx"
	
	private OpTracker 			tracker
			ObjLocator?			objLocator

	** nullable & internal for testing only
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

	static Obj? withCtx(ObjLocator objLocator, OpTracker? tracker, |->Obj?| f) {
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
		ctx := InjectCtx(InjectionType.dependencyByType) {
			it.dependencyType = dependencyType
		}
		return ThreadStack.pushAndRun(injectCtxId, ctx, func)
	}
	
	static Obj? doingFieldInjection(Obj injectingInto, Field field, |->Obj?| func) {
		ctx := InjectCtx(InjectionType.fieldInjection) {
			it.injectingInto	= injectingInto
			it.injectingIntoType= injectingInto.typeof
			it.dependencyType	= field.type
			it.field			= field
			it.fieldFacets		= field.facets
		}
		return ThreadStack.pushAndRun(injectCtxId, ctx, func)
	}

	static Obj? doingFieldInjectionViaItBlock(Type injectingIntoType, Field field, |->Obj?| func) {
		ctx := InjectCtx(InjectionType.fieldInjection) {
			it.injectingIntoType= injectingIntoType
			it.dependencyType	= field.type
			it.field			= field
			it.fieldFacets		= field.facets
		}
		return ThreadStack.pushAndRun(injectCtxId, ctx, func)
	}

	static Obj? doingMethodInjection(Obj? injectingInto, Method method, |->Obj?| func) {
		ctx := InjectCtx(InjectionType.methodInjection) {
			it.injectingInto	= injectingInto
			it.injectingIntoType= method.parent
			it.method			= method
			it.methodFacets		= method.facets		
		}
		return ThreadStack.pushAndRun(injectCtxId, ctx, func)
	}

	static Obj? doingCtorInjection(Type injectingIntoType, Method ctor, |->Obj?| func) {
		ctx := InjectCtx(InjectionType.methodInjection) {
			it.injectingIntoType= injectingIntoType
			it.method			= ctor
			it.methodFacets		= ctor.facets
		}
		return ThreadStack.pushAndRun(injectCtxId, ctx, func)
	}

	static Obj? doingParamInjection(Param param, Int index, |->Obj?| func) {
		ctx := (InjectCtx) ThreadStack.peek(injectCtxId)
		ctx.dependencyType		= param.type
		ctx.methodParam			= param
		ctx.methodParamIndex	= index
		return func.call
	}

	// ----
	
	static ProviderCtx providerCtx() {
		ctx := (InjectCtx) ThreadStack.peek(injectCtxId)
		return ctx.toProviderCtx
	}
	
	static InjectionCtx? peek(Bool checked := true) {
		ThreadStack.peek(injectionCtxId, checked)
	}
}

internal class InjectCtx {
	InjectionType 	injectionType
	
	Obj?			injectingInto
	Type?			injectingIntoType
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
	
	ProviderCtx toProviderCtx() {
		ProviderCtx {
			it.injectionType		= this.injectionType
			it.injectingInto		= this.injectingInto
			it.injectingIntoType	= this.injectingIntoType
			it.dependencyType		= this.dependencyType
			it.field				= this.field
			it.fieldFacets			= this.fieldFacets ?: Facet#.emptyList
			it.method				= this.method
			it.methodFacets			= this.methodFacets ?: Facet#.emptyList
			it.methodParam			= this.methodParam
			it.methodParamIndex		= this.methodParamIndex
		}
	}
}
