using concurrent::AtomicBool
using concurrent::AtomicRef
using concurrent::Actor
using afIoc::ConcurrentState

** Should we add this source to the generated proxy pods, and delete it from afIoc?
** For now, no. It'll speed up the compiler, and no-one discovers @NoDoc classes anyway!
** 
** @since 1.3
@NoDoc
const class LazyService {
	private const ConcurrentState 	conState	:= ConcurrentState(LazyServiceState#)
	private const ThreadStash		threadStash
	private const ServiceDef 		serviceDef
	private const ObjLocator		objLocator

	internal new make(ServiceDef serviceDef, ObjLocator objLocator) {
		stashManager 		:= (ThreadStashManager) objLocator.trackServiceById(ServiceIds.threadStashManager)
		this.serviceDef 	= serviceDef
		this.objLocator 	= objLocator
		this.threadStash	= stashManager.createStash(serviceDef.serviceId + "-proxy")
	}

	Obj? call(Method method, Obj?[] args) {
		serviceInvoker.invokeMethod(method, args)
	}

	Obj service() {
		serviceInvoker.service
	}

	internal ServiceMethodInvoker serviceInvoker() {
		(serviceDef.scope == ServiceScope.perApplication) ? getViaAppScope : getViaThreadScope
	}

	private ServiceMethodInvoker getViaAppScope() {
		return InjectionCtx.withCtx(objLocator, null) |->Obj?| {
			Unsafe ctxWrapper := Unsafe(InjectionCtx.peek)	// pass ctx into the state thread
			return getState |state->Obj?| {
				 ThreadStack.pushAndRun(InjectionCtx.injectionCtxId, ctxWrapper.val) |InjectionCtx ctx2 -> Obj?| {
					return state.getCaller(objLocator, serviceDef).toConst 
				 }
			}
		}
	}

	private ServiceMethodInvoker getViaThreadScope() {
		return ((LazyServiceState) threadStash.get("state", |->Obj| { LazyServiceState() })).getCaller(objLocator, serviceDef)
	}

	private Obj? getState(|LazyServiceState -> Obj?| state) {
		conState.getState(state)
	}

	override Str toStr() {
		"LazyService for ${serviceDef.serviceId}"
	}
}

** @since 1.3.0
internal class LazyServiceState {	
	private ServiceMethodInvokerThread? invoker

	** this does *actually* return the Thread'ed version of `ServiceMethodInvoker`, the called may 
	** optionally call .toConst() if needed 
	ServiceMethodInvokerThread getCaller(ObjLocator objLocator, ServiceDef serviceDef) {
		if (invoker != null)
			return invoker

		return InjectionCtx.withCtx(objLocator, null) |->Obj?| {
			invoker = InjectionCtx.track("Lazily creating '$serviceDef.serviceId'") |->Obj| {	
				invokerSrc 	:= (AspectInvokerSource) objLocator.trackServiceById(ServiceIds.aspectInvokerSource)
				invoker		:= invokerSrc.createServiceMethodInvoker(serviceDef)
				return invoker
			}
			return invoker
		}
	}
}

