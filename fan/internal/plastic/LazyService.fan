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
	private const LocalStash		threadState	:= LocalStash(LazyServiceState#)
	private const ServiceDef 		serviceDef
	private const ObjLocator		objLocator
	private const Bool				appScope
	
	internal new make(ServiceDef serviceDef, ObjLocator objLocator, Bool appScope) {
		this.serviceDef = serviceDef
		this.objLocator = objLocator
		this.appScope	= appScope
	}

	Obj? call(Method method, Obj?[] args) {
		ctx := InjectionCtx(objLocator, OpTracker(LogLevel.info))
		adviceSource 	:= (AdviceSource) objLocator.trackServiceById(ctx, ServiceIds.adviceSource)
		methodAdvisors	:= adviceSource.getMethodAdvisors(ctx, serviceDef)
		
//		TODO: cache advisors
		
		methodAdvisor := methodAdvisors.findAll { it.method == method }.first
		
		return methodAdvisor.callOn(get, args)
	}
	
	Obj get() {
		appScope ? getViaAppScope : getViaThreadScope
	}

	private Obj getViaAppScope() {
		return getState { getService(objLocator, serviceDef) }
	}

	private Obj getViaThreadScope() {
		return ((LazyServiceState) threadState.get("state", |->Obj| { LazyServiceState() })).getService(objLocator, serviceDef)
	}

	private Obj? getState(|LazyServiceState -> Obj?| state) {
		conState.getState(state)
	}
}

** @since 1.3
internal class LazyServiceState {
	private Obj? service
	
	Obj getService(ObjLocator objLocator, ServiceDef serviceDef) {
		if (service != null)
			return service
		
		ctx := InjectionCtx(objLocator)
		return ctx.track("Lazily creating '$serviceDef.serviceId'") |->Obj| {	
			objLocator.getService(ctx, serviceDef, true)
		}
	}
}