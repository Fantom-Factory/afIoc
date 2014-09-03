
**
** Passed into module advisor methods to allow the method to, err, advise services!
** 
** @see The `Advise` facet for more details.
** 
** @since 1.3.0
class MethodAdvisor {
	internal |MethodInvocation invocation -> Obj?|[]? aspects
	
	** The method to advise
	const Method	method
	
	internal new make(Method method) {
		this.method = method
	}
	
	** Add an aspect that will be called when the method is invoked
	Void addAdvice(|MethodInvocation invocation -> Obj?| aspect) {
		if (aspects == null)
			aspects = [,]
		aspects.add(aspect)
	}

	// given I've never needed to override method advice (and realistically I'm the only one using 
	// afIoc!) we'll not order the advice for now
//	abstract Void addOrderedAdvice(Str id, Str[] orderingConstraints, |Obj target, Obj[] args| aspect)
//	abstract Void overrideOrderedAdvice(Str idToOverride, Str id, Str[] orderingConstraints, |Obj target, Obj[] args| aspect)
}

** Used by aspects to call the method they wrap.
** 
** The wrapped method is purposely hidden so no-one is tempted to call it directly, use [invoke()]`#invoke` instead.  
** The real method is hidden behind this class so multiple Method Advisors can be chained
** 
** @see The `Advise` facet for more details.
** 
** @since 1.3.0
class MethodInvocation {
	** The instance of the service the method will be called on
	Obj		service
	
	** A mutable list of arguments the method will be called with
	Obj?[]	args

	internal Method? method
	internal Int index
	internal |MethodInvocation invocation -> Obj?|[]? aspects

	internal new make(|This|f) { f(this) }

	** Call the next method advice in the pipeline, or the real method - you'll never know which!
	Obj? invoke() {
		index++
		if (aspects != null && index <= aspects.size)
			return aspects[-index].call(this)
		
		return method.callOn(service, args)
	}
}
