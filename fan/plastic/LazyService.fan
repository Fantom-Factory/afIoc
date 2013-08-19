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

	internal new make(InjectionCtx ctx, ServiceDef serviceDef, ObjLocator objLocator) {
		stashManager 		:= (ThreadStashManager) objLocator.trackServiceById(ctx, ServiceIds.threadStashManager)
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
		return getState { getCaller(objLocator, serviceDef).toConst }
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

		ctx 	:= InjectionCtx(objLocator)
		invoker = ctx.track("Lazily creating '$serviceDef.serviceId'") |->Obj| {	
			invokerSrc 	:= (AspectInvokerSource) objLocator.trackServiceById(ctx, ServiceIds.aspectInvokerSource)
			invoker		:= invokerSrc.createServiceMethodInvoker(ctx, serviceDef)
			return invoker
		}

		return invoker
	}
}

