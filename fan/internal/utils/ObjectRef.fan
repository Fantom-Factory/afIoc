using concurrent::AtomicRef

internal const class ObjectRef {
	private const AtomicRef? 	atomObj
	private const ThreadStash?	threadStash
	
	new make(ThreadStash threadStash, ServiceScope scope, Obj? obj) {
		if (scope == ServiceScope.perApplication)
			this.atomObj = AtomicRef()
		else
			this.threadStash = threadStash
		this.object = obj
	}
	
	Obj? object {
		get {
			if (atomObj != null)		return atomObj.val
			if (threadStash != null)	return threadStash["objectRef"]
			return null
		}
		set { 
			if (atomObj != null)		atomObj.val = it 
			if (threadStash != null)	threadStash["objectRef"] = it
		}
	}	
}
