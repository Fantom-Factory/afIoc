
internal class InjectionCtx {
	
	OpTracker tracker	:= OpTracker()
	ObjLocator objLocator
	
	new make(ObjLocator objLocator) {
		this.objLocator = objLocator
	}
	
	Obj? track(Str description, |->Obj?| operation) {
		tracker.track(description, operation)
	}
	
	Void log(Str description) {
		tracker.log(description)
	}
}
