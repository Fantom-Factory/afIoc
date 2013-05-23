
** @since 1.3.0
const mixin AdviceSource {
	
	abstract internal MethodAdvisor[] getMethodAdvisors(InjectionCtx ctx, ServiceDef serviceDef)
	
}

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

**
** @see The `Advice` facet for more details.
** 
** @since 1.3.0
class MethodAdvisor {

	** The method to advise
	Method	method
	
	private |Obj target, Obj[] args -> Obj?|[] aspects	:= [,]
	
	new make(Method method) {
		this.method = method
	}
	
	** Add an aspect to callback method advice
	Void addAdvice(|Obj target, Obj[] args -> Obj?| aspect) {
		aspects.add(aspect)
	}

	internal Obj? call(Obj target, Obj[] args) {
		if (aspects.isEmpty)
			return method.callOn(target, args)
		// FIXME: need to pipeline the calls
		ret := aspects.map { it.call(target, args) }
		return ret.isEmpty ? null : ret.get(0)
	}

	// given I've never need to override method advice (and realistically I'm the only one using 
	// afIoc!) we'll not order the advice for now
//	abstract Void addOrderedMethodAdvice(Str id, Str[] orderingConstraints, |Obj target, Obj[] args| aspect)
//	abstract Void overrideOrderedMethodAdvice(Str idToOverride, Str id, Str[] orderingConstraints, |Obj target, Obj[] args| aspect)
}
