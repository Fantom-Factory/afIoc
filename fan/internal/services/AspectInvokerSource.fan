using afConcurrent::LocalRef

** (Service) - Can't be internal since it's used by auto-generated lazy services.
** 
** @since 1.3.0
@NoDoc
const mixin AspectInvokerSource {
	
	abstract internal ServiceMethodInvoker createServiceMethodInvoker(ServiceDef serviceDef)
}

** @since 1.3.0
internal const class AspectInvokerSourceImpl : AspectInvokerSource {

// 	As clean as this is, we can't use it, because we get recursion from DepProviders who require
//	injected lazy services.
//	@Inject @ServiceId { id="registry" }

	private const Registry	registry
	private ObjLocator objLocator() { (ObjLocator) registry }

	private const ThreadLocalManager	localManager
	
	new make(ThreadLocalManager localManager, Registry registry) {
		this.localManager	= localManager
		this.registry 		= registry
	}

	** Returns `MethodAdvisor`s fully loaded with callbacks
	override ServiceMethodInvoker createServiceMethodInvoker(ServiceDef serviceDef) {

		// create a MethodAdvisor for each (non-Obj) method to be advised
		methodAdvisors := (MethodAdvisor[]) serviceDef.serviceType.methods.rw
			.exclude { Obj#.methods.contains(it) }
			.map |m->MethodAdvisor| { MethodAdvisor(m) }
		
		// find all module @Advise methods
		adviceDefs := (AdviceDef[]) InjectionTracker.track("Gathering advisors for service '$serviceDef.serviceId'") |->AdviceDef[]| {
			ads := objLocator.adviceByServiceDef(serviceDef)
			InjectionTracker.log("Found $ads.size method(s)")
			return ads
		}
		
		// call the module @Advise methods, filling up the MethodAdvisors
		if (!adviceDefs.isEmpty)
			InjectionTracker.track("Gathering advice for service '$serviceDef.serviceId'") |->| {
				adviceDefs.each { 
					InjectionUtils.callMethod(it.advisorMethod, null, [methodAdvisors])
				}
			}

		service 	:= objLocator.getService(serviceDef, true)
		adviceMap	:= [Method:|MethodInvocation invocation -> Obj?|[]][:]
		
		methodAdvisors.each {
			adviceMap[it.method] = it.aspects
		}

		localRef := localManager.createRef(serviceDef.serviceId + "-invoker")
		return ServiceMethodInvoker {
			it.service = ObjectRef(localRef, serviceDef.scope, service)
			it.aspects = adviceMap.toImmutable
		}
	}
}

internal const class ServiceMethodInvoker {
	const ObjectRef service
	const Method:|MethodInvocation invocation -> Obj?|[] aspects
	
	new make(|This|in) { in(this) }
	
	Obj? invokeMethod(Method method, Obj?[] args) {
		return MethodInvocation {
			it.service	= this.service.object
			it.aspects	= this.aspects[method]
			it.method	= method
			it.args		= args
			it.index	= 0
		}.invoke
	}
}

