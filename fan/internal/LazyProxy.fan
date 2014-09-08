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
internal const class LazyProxyImpl : LazyProxy {
	private const ObjLocator			objLocator
	private const AspectInvokerSource	invokerSrc
	private const ServiceDef 			serviceDef
	private const AtomicRef				serviceInvokerRef	:= AtomicRef(null)

	internal new make(ObjLocator objLocator, ServiceDef serviceDef) {
		this.objLocator 	= objLocator
		this.invokerSrc 	= objLocator.trackServiceById(AspectInvokerSource#.qname, true)
		this.serviceDef 	= serviceDef
	}

	override Obj? call(Method method, Obj?[] args) {
		serviceInvoker.invokeMethod(method, args)
	}

	override Obj service() {
		serviceInvoker.service.val
	}

	private ServiceMethodInvoker serviceInvoker() {
		if (serviceInvokerRef.val != null) {
			smi := (ServiceMethodInvoker) serviceInvokerRef.val
			// make sure the invoker still has a service to invoke!
			// if not (due to use being a diff thread) we'll just make a new one!
			if (smi.service.val != null)
				return smi
		}

		serviceInvokerRef.val = InjectionTracker.withCtx(null) |->Obj?| {
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
