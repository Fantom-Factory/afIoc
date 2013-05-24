
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
		MethodInvocation {
			it.service	= service
			it.args		= args
			it.method	= this.method
			it.index	= 0
			it.aspects	= this.aspects
		}.invoke
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
	Obj?[]	args

	internal Method? method
	internal Int index
	internal |MethodInvocation invocation -> Obj?|[] aspects

	internal new make(|This|f) { f(this) }

	** Call the next method advice in the pipeline, or the real method - you'll never know which!
	Obj? invoke() {
		index++
		if (index <= aspects.size)
			return aspects[-index].call(this)
		
		return method.callOn(service, args)
	}
}
