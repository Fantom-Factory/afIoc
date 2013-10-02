
** @since 1.3.0
internal const class AspectInvokerSourceImpl : AspectInvokerSource {

// 	As clean as this is, we can't use it, because we get recursion from DepProviders who require
//	injected lazy services.
//	@Inject @ServiceId { serviceId="registry" }

	@Inject
	const Registry	registry
	private ObjLocator objLocator() { (ObjLocator) registry }

	new make(|This|in) {
		in(this)
	}

	** Returns `MethodAdvisor`s fully loaded with callbacks
	override ServiceMethodInvokerThread createServiceMethodInvoker(InjectionCtx ctx, ServiceDef serviceDef) {

		// create a MethodAdvisor for each (non-Obj) method to be advised
		methodAdvisors := (MethodAdvisor[]) serviceDef.serviceType.methods.rw
			.exclude { Obj#.methods.contains(it) }
			.map |m->MethodAdvisor| { MethodAdvisor(m) }
		
		// find all module @Advise methods
		adviceDefs := (AdviceDef[]) ctx.track("Gathering advisors for service '$serviceDef.serviceId'") |->AdviceDef[]| {
			ads := objLocator.adviceByServiceDef(serviceDef)
			ctx.log("Found $ads.size method(s)")
			return ads
		}
		
		// call the module @Advise methods, filling up the MethodAdvisors
		if (!adviceDefs.isEmpty)
			ctx.track("Gathering advice for service '$serviceDef.serviceId'") |->| {
				adviceDefs.each { 
					InjectionUtils.callMethod(ctx, it.advisorMethod, null, [methodAdvisors])
				}
			}

		service 	:= objLocator.getService(ctx, serviceDef, true)
		adviceMap	:= [Method:|MethodInvocation invocation -> Obj?|[]][:]
		
		methodAdvisors.each {
			adviceMap[it.method] = it.aspects
		}

		return ServiceMethodInvokerThread {
			it.service = service
			it.aspects = adviceMap.toImmutable
		}
	}
}

internal mixin ServiceMethodInvoker {
	abstract Obj service()
	abstract Method:|MethodInvocation invocation -> Obj?|[] aspects()
	
	Obj? invokeMethod(Method method, Obj?[] args) {
		return MethodInvocation {
			it.service	= this.service
			it.aspects	= this.aspects[method]
			it.method	= method
			it.args		= args
			it.index	= 0
		}.invoke
	}
}

internal class ServiceMethodInvokerThread : ServiceMethodInvoker {
	override Obj service
	override Method:|MethodInvocation invocation -> Obj?|[] aspects
	new make(|This|in) { in(this) }
	
	ServiceMethodInvokerConst toConst() {
		ServiceMethodInvokerConst {
			it.service = this.service
			it.aspects = this.aspects
		}
	}
}

** Same as `AspectServiceInvokerThread` just const so it can pass between threads
internal const class ServiceMethodInvokerConst : ServiceMethodInvoker {
	override const Obj service
	override const Method:|MethodInvocation invocation -> Obj?|[] aspects
	new make(|This|in) { in(this) }
}
