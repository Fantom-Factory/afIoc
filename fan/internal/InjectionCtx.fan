
internal class InjectionCtx {
	
	private ServiceDef[]			defStack		:= [,]
	private DependencyProvider[]	contribStack	:= [,]
	OpTracker 						tracker			:= OpTracker()
	ObjLocator? 					objLocator
	
	new make(ObjLocator? objLocator) {
		this.objLocator = objLocator
	}
	
	Obj? track(Str description, |->Obj?| operation) {
		tracker.track(description, operation)
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
				if (it.serviceId == def.serviceId)
					throw IocErr(IocMessages.serviceRecursion(defStack.map { it.serviceId }))
			}
			
			return operation()
			
		} finally {
			defStack.pop			
		}
	}
	
	Obj? withDependencyProvider(DependencyProvider dependencyProvider, |->Obj?| operation) {
		contribStack.push(dependencyProvider)
		try {
			return operation()
		} finally {			
			contribStack.pop
		}
	}
	
	Obj? provideDependency(Type dependencyType) {
		// jus' passin' thru!
		contribStack.peek?.provide(dependencyType)
	}
}
