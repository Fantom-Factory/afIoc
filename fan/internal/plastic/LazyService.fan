using concurrent::AtomicBool
using concurrent::AtomicRef
using afIoc::ConcurrentState

** Should we add this source to the generated proxy pods, and delete it from afIoc?
** For now, no. It'll speed up the compiler, and no-one discovers @NoDoc classes anyway!
@NoDoc
const class LazyService {
	private const ConcurrentState 	conState	:= ConcurrentState(LazyServiceState#)
	private const ServiceDef 		serviceDef
	private const ObjLocator		objLocator
	
	internal new make(ServiceDef serviceDef, ObjLocator objLocator) {
		this.serviceDef = serviceDef
		this.objLocator = objLocator
	}

	Obj get() {		
		getState { getService(objLocator, serviceDef) }
	}

	private Obj? getState(|LazyServiceState -> Obj?| state) {
		conState.getState(state)
	}
}

internal class LazyServiceState {
	private Obj? service
	
	Obj getService(ObjLocator objLocator, ServiceDef serviceDef) {
		if (service != null)
			return service
		
		ctx := InjectionCtx(objLocator)
		return ctx.track("Lazily creating '$serviceDef.serviceId'") |->Obj| {	
			objLocator.getService(ctx, serviceDef)
		}
	}
}