using concurrent::AtomicRef

** Should we add this source to the generated proxy pods, and delete it from afIoc?
** For now, no. It'll speed up the compiler, and no-one discovers @NoDoc classes anyway!
** 
** @since 1.3
@NoDoc
const mixin LazyProxy {
	** used to call methods
	abstract Obj? call(Method method, Obj?[] args)
	
	** used to access fields
	abstract Obj service()
}

** Lazily finds and calls a *service*
internal const class LazyProxyForService : LazyProxy {
	private const ObjLocator			objLocator
	private const AspectInvokerSource	invokerSrc
	private const ServiceDef 			serviceDef
	private const AtomicRef				serviceInvokerRef	:= AtomicRef(null)

	internal new make(ObjLocator objLocator, ServiceDef serviceDef) {
		this.objLocator 	= objLocator
		this.invokerSrc 	= objLocator.trackServiceById(ServiceIds.aspectInvokerSource)
		this.serviceDef 	= serviceDef
	}

	override Obj? call(Method method, Obj?[] args) {
		serviceInvoker.invokeMethod(method, args)
	}

	override Obj service() {
		serviceInvoker.service.object
	}

	internal ServiceMethodInvoker serviceInvoker() {
		if (serviceInvokerRef.val != null) {
			smi := (ServiceMethodInvoker) serviceInvokerRef.val
			// make sure the invoker still has a serivce to invoke!
			// if not (due to use being a diff thread) we'll just make a new one!
			if (smi.service.object != null)
				return smi
		}

		serviceInvokerRef.val = InjectionTracker.withCtx(objLocator, null) |->Obj?| {
			InjectionTracker.track("Lazily creating '$serviceDef.serviceId'") |->Obj| {	
				invokerSrc.createServiceMethodInvoker(serviceDef)
			}
		}

		return serviceInvokerRef.val
	}

	override Str toStr() {
		"LazyProxyForService ${serviceDef.serviceId}"
	}
}

** Lazily creates and calls any *instance*, as provided by createProxy() 
internal const class LazyProxyForMixin : LazyProxy {
	private const ConcurrentState 	conState	:= ConcurrentState(LazyProxyForMixinState#)
	private const ThreadStash		threadStash
	private const ServiceDef 		serviceDef
	private const ObjLocator		objLocator

	internal new make(ServiceDef serviceDef, ObjLocator objLocator) {
		stashManager 		:= (ThreadStashManager) objLocator.trackServiceById(ServiceIds.threadStashManager)
		this.serviceDef 	= serviceDef
		this.objLocator 	= objLocator
		this.threadStash	= stashManager.createStash(serviceDef.serviceId + "-proxy")
	}

	override Obj? call(Method method, Obj?[] args) {
		method.callOn(getInstance, args)
	}

	override Obj service() {
		getInstance
	}

	internal Obj getInstance() {
		serviceDef.serviceType.isConst ? getViaAppScope : getViaThreadScope
	}

	private Obj getViaAppScope() {
		return InjectionTracker.withCtx(objLocator, null) |->Obj?| {
			ctxWrapper := Unsafe(InjectionTracker.peek)	// pass ctx into the state thread
			return conState.getState |LazyProxyForMixinState state->Obj?| {
				 ThreadStack.pushAndRun(InjectionTracker.trackerId, ctxWrapper.val) |->Obj?| {
					return state.getInstance(objLocator, serviceDef)
				 }
			}
		}
	}

	private Obj getViaThreadScope() {
		return ((LazyProxyForMixinState) threadStash.get("state", |->Obj| { LazyProxyForMixinState() })).getInstance(objLocator, serviceDef)
	}

	override Str toStr() {
		"LazyProxyForMixin for ${serviceDef.serviceId}"
	}
}

internal class LazyProxyForMixinState {	
	private Obj? instance

	Obj getInstance(ObjLocator objLocator, ServiceDef serviceDef) {
		if (instance != null)
			return instance

		return InjectionTracker.withCtx(objLocator, null) |->Obj?| {
			return InjectionTracker.track("Lazily creating '$serviceDef.serviceId'") |->Obj| {	
				return serviceDef.createServiceBuilder.call
			}
		}
	}
}