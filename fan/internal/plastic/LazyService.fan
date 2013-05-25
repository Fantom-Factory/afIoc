using concurrent::AtomicBool
using concurrent::AtomicRef
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
	
	internal new make(OpTracker tracker, ServiceDef serviceDef, ObjLocator objLocator) {
		stashManager 		:= (ThreadStashManager) objLocator.serviceDefById(ServiceIds.threadStashManager)
		this.serviceDef 	= serviceDef
		this.objLocator 	= objLocator
		this.threadStash	= stashManager.createStash("lazy-" + serviceDef.serviceId)
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
		return getState { getCaller(objLocator, serviceDef).toConst }
	}

	private ServiceMethodInvoker getViaThreadScope() {
		return ((LazyServiceState) threadStash.get("state", |->Obj| { LazyServiceState() })).getCaller(objLocator, serviceDef)
	}

	private Obj? getState(|LazyServiceState -> Obj?| state) {
		conState.getState(state)
	}
}

** @since 1.3.0
internal class LazyServiceState {	
	private ServiceMethodInvokerThread? caller
	
	ServiceMethodInvokerThread getCaller(ObjLocator objLocator, ServiceDef serviceDef) {
		if (caller != null)
			return caller
		
		ctx := InjectionCtx(objLocator)
		return ctx.track("Lazily creating '$serviceDef.serviceId'") |->Obj| {	
			invokerSrc 	:= (AspectInvokerSource) objLocator.trackServiceById(ctx, ServiceIds.aspectInvokerSource)
			invoker		:= invokerSrc.createServiceMethodInvoker(ctx, serviceDef)
			return invoker
		}
	}
}

