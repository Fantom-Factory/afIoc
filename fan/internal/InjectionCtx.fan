
internal class InjectionCtx {

	private ServiceDef[]			defStack		:= [,]
	private DependencyProvider[]	providerStack	:= [,]
	private OpTracker 				tracker
	ObjLocator? 					objLocator

	new make(ObjLocator? objLocator, OpTracker tracker := OpTracker()) {
		this.objLocator = objLocator
		this.tracker	= tracker
	}

	Obj? track(Str description, |->Obj?| operation) {
		tracker.track(description, operation)
	}

	Void logExpensive(|->Str| msg) {
		tracker.logExpensive(msg)
	}

	Void log(Str description) {
		tracker.log(description)
	}

	Obj? withServiceDef(ServiceDef def, |->Obj?| operation) {
		// check for allowed scope
		if (defStack.peek?.scope == ServiceScope.perApplication && def.scope == ServiceScope.perThread)
			throw IocErr(IocMessages.threadScopeInAppScope(defStack.peek.serviceId, def.serviceId))

		defStack.push(def)

		try {
			// check for recursion
			defStack[0..<-1].each { 
				// the servicedef may be the same, but if the scope is perInjection, the instances will be different
				if (it.serviceId == def.serviceId && def.scope != ServiceScope.perInjection)
					throw IocErr(IocMessages.serviceRecursion(defStack.map { it.serviceId }))
			}

			return operation.call()

		} finally {
			defStack.pop			
		}
	}

	Obj? withProvider(DependencyProvider provider, |->Obj?| operation) {
		providerStack.push(provider)
		try {
			return operation.call()
		} finally {			
			providerStack.pop
		}
	}

	ServiceDef? building() {
		def := defStack.peek
		if (def?.scope == ServiceScope.perInjection)
			def = defStack[-2]
		return def
	}
	
	Obj? provideDependency(Type dependencyType) {
		// jus' passin' thru!
		providerStack.peek?.provide(providerCtx, dependencyType)
	}
	
	ProviderCtx providerCtx() {
		ProviderCtx {
			it.injectionCtx = this
		}
	}
}
