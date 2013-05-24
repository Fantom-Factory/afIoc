
** @since 1.3.0
internal const class AdviceSourceImpl : AdviceSource {
	
	@Inject @ServiceId { serviceId="registry" }
	const ObjLocator objLocator
	
	new make(|This|in) {
		in(this)
	}
	
	** Returns `MethodAdvisor`s fully loaded with callbacks
	override MethodAdvisor[] getMethodAdvisors(InjectionCtx ctx, ServiceDef serviceDef) {
				
		adviceDefs := (AdviceDef[]) ctx.track("Gathering advisors for service '$serviceDef.serviceId'") |->AdviceDef[]| {
			objLocator.adviceByServiceDef(serviceDef)
		}
		ctx.log("Found $adviceDefs.size method(s)")
		
		methodAdvisors := serviceDef.serviceType.methods.rw
			.exclude { Obj#.methods.contains(it) }
			.map |m->MethodAdvisor| { MethodAdvisor(m) }
		
		ctx.track("Gathering advice for service '$serviceDef.serviceId'") |->| {
			adviceDefs.each { 
				InjectionUtils.callMethod(ctx, it.advisorMethod, null, [methodAdvisors])
			}
		}
		
		return methodAdvisors
	}
}

