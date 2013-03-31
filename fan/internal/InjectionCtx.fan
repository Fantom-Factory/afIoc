
internal class InjectionCtx {
	
	private ServiceDef[]	defStack	:= [,]
	OpTracker 				tracker		:= OpTracker()
	ObjLocator? 				objLocator
	
	new make(ObjLocator? objLocator) {
		this.objLocator = objLocator
//		InjectionCtx#track.params[0].type.
	}
	
	Obj? track(Str description, |->Obj?| operation) {
		tracker.track(description, operation)
	}
	
	Void log(Str description) {
		tracker.log(description)
	}
	
	Void pushDef(ServiceDef def) {
		// check for allowed scope
		if (defStack.peek?.scope == ServiceScope.perApplication && def.scope == ServiceScope.perThread)
			throw IocErr(IocMessages.threadScopeInAppScope(defStack.peek.serviceId, def.serviceId))
		
		defStack.push(def)

		// check for recursion
		defStack[0..<-1].each { 
			if (it.serviceId == def.serviceId)
				throw IocErr(IocMessages.serviceRecursion(defStack.map { it.serviceId }))
		}
	}
	
	Void popDef() {
		defStack.pop
	}
	
	ServiceDef? peekDef() {
		defStack.peek
	}
}
