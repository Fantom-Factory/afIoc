using concurrent::AtomicBool
using concurrent::AtomicRef
using concurrent::Actor
using afIoc::ConcurrentState

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

internal const class LazyProxyForService : LazyProxy {
	private const ConcurrentState 	conState	:= ConcurrentState(LazyProxyForServiceState#)
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
		serviceInvoker.invokeMethod(method, args)
	}

	override Obj service() {
		serviceInvoker.service
	}

	internal ServiceMethodInvoker serviceInvoker() {
		(serviceDef.scope == ServiceScope.perApplication) ? getViaAppScope : getViaThreadScope
	}

	private ServiceMethodInvoker getViaAppScope() {
		return InjectionTracker.withCtx(objLocator, null) |->Obj?| {
			Unsafe ctxWrapper := Unsafe(InjectionTracker.peek)	// pass ctx into the state thread
			return conState.getState |LazyProxyForServiceState state->Obj?| {
				 ThreadStack.pushAndRun(InjectionTracker.trackerId, ctxWrapper.val) |->Obj?| {
					return state.getCaller(objLocator, serviceDef).toConst 
				 }
			}
		}
	}

	private ServiceMethodInvoker getViaThreadScope() {
		return ((LazyProxyForServiceState) threadStash.get("state", |->Obj| { LazyProxyForServiceState() })).getCaller(objLocator, serviceDef)
	}

	override Str toStr() {
		"LazyProxyForService ${serviceDef.serviceId}"
	}
}

** @since 1.3.0
internal class LazyProxyForServiceState {	
	private ServiceMethodInvokerThread? invoker

	** this does *actually* return the Thread'ed version of `ServiceMethodInvoker`, the called may 
	** optionally call .toConst() if needed 
	ServiceMethodInvokerThread getCaller(ObjLocator objLocator, ServiceDef serviceDef) {
		if (invoker != null)
			return invoker

		return InjectionTracker.withCtx(objLocator, null) |->Obj?| {
			invoker = InjectionTracker.track("Lazily creating '$serviceDef.serviceId'") |->Obj| {	
				invokerSrc 	:= (AspectInvokerSource) objLocator.trackServiceById(ServiceIds.aspectInvokerSource)
				invoker		:= invokerSrc.createServiceMethodInvoker(serviceDef)
				return invoker
			}
			return invoker
		}
	}
}

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
			Unsafe ctxWrapper := Unsafe(InjectionTracker.peek)	// pass ctx into the state thread
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