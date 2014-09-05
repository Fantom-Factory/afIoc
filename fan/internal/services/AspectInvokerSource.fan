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

	private const ThreadLocalManager	localManager
	
	new make(ThreadLocalManager localManager) {
		this.localManager	= localManager
	}

	** Returns `MethodAdvisor`s fully loaded with callbacks
	override ServiceMethodInvoker createServiceMethodInvoker(ServiceDef serviceDef) {

		// create a MethodAdvisor for each (non-Obj) method to be advised
		methodAdvisors := (MethodAdvisor[]) serviceDef.serviceType.methods.rw
			.exclude { Obj#.methods.contains(it) }
			.map |m->MethodAdvisor| { MethodAdvisor(m) }
		
		// find all module @Advise methods
		adviceDefs := (AdviceDef[]) InjectionTracker.track("Gathering advisors for service '$serviceDef.serviceId'") |->AdviceDef[]| {
			ads := serviceDef.adviceDefs ?: AdviceDef#.emptyList
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

		service 	:= serviceDef.getRealService
		adviceMap	:= [Method:|MethodInvocation invocation -> Obj?|[]?][:]
		
		methodAdvisors.each {
			adviceMap[it.method] = it.aspects
		}

		localRef := localManager.createRef(serviceDef.serviceId + "-invoker")
		return ServiceMethodInvoker {
			it.service = ObjectRef(localRef, serviceDef.serviceScope, service)
			it.aspects = adviceMap.toImmutable
		}
	}
}

internal const class ServiceMethodInvoker {
	const ObjectRef service
	const Method:|MethodInvocation invocation -> Obj?|[]? aspects
	
	new make(|This|in) { in(this) }

	Obj? invokeMethod(Method method, Obj?[] args) {
		return MethodInvocation {
			if (this.service.object == null)
				throw WtfErr("ObjectRef '${this.service.name}' with scope '${this.service.scope}' is null!???")
			it.service	= this.service.object
			it.aspects	= this.aspects[method]
			it.method	= method
			it.args		= args
			it.index	= 0
		}.invoke
	}
}

