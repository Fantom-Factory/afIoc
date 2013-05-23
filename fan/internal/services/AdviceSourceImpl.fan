
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
** Passed into module advisor methods to allow the method to, err, advise services!
** 
** @see The `Advice` facet for more details.
** 
** @since 1.3.0
class MethodAdvisor {

	** The method to advise
	Method	method
	
	private |MethodInvocation invocation -> Obj?|[] aspects	:= [,]
	
	internal new make(Method method) {
		this.method = method
	}
	
	** Add an aspect to callback method advice
	Void addAdvice(|MethodInvocation invocation -> Obj?| aspect) {
		aspects.add(aspect)
	}

	internal Obj? callOn(Obj service, Obj[] args) {
		
		terminator := MethodInvocation {
			it.service	= service
			it.method	= this.method
		}
		
		wrapped := terminator
		
		aspects.eachr { 
			aspect := it
			wrapped = MethodInvocation { 
				it.service	= service
				it.aspect 	= aspect 
			}
		}

		return wrapped.invoke
	}

	// given I've never need to override method advice (and realistically I'm the only one using 
	// afIoc!) we'll not order the advice for now
//	abstract Void addOrderedMethodAdvice(Str id, Str[] orderingConstraints, |Obj target, Obj[] args| aspect)
//	abstract Void overrideOrderedMethodAdvice(Str idToOverride, Str id, Str[] orderingConstraints, |Obj target, Obj[] args| aspect)
}

** The real method is hidden behind this class so multiple Method Advisors can be chained
** 
** @since 1.3.0
class MethodInvocation {
	Obj		service
	Obj		target	:= 0
	Obj?[]	args	:= Obj#.emptyList

	internal |MethodInvocation invocation -> Obj?|? aspect
	internal Method? method

	internal new make(|This|f) { f(this) }

	** Call the next method advice in the pipeline, or the real method - you'll never know which!
	Obj? invoke() {
		if (method != null)
			return method.callOn(service, args)
		return aspect.callOn(target, args)
	}

	internal Obj? callOn(Obj target, Obj[]? args) {
		this.target = target
		this.args 	= args
		return aspect.call(this)
	}
}
