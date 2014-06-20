using concurrent::AtomicRef
using afConcurrent::LocalRef

internal const class ObjectRef {
			const Str 			name
			const ServiceScope	scope
	private const AtomicRef? 	atomicObj
	private const LocalRef?		localObj
	
	new make(LocalRef localRef, ServiceScope scope, Obj? obj) {
		if (scope == ServiceScope.perApplication)
			this.atomicObj = AtomicRef()
		else
			this.localObj = localRef
		this.object = obj
		this.name	= localRef.name
		this.scope	= scope
	}
	
	Obj? object {
		get {
			if (atomicObj != null)	return atomicObj.val
			if (localObj  != null)	return localObj.val
			return null
		}
		set { 
			if (atomicObj != null)	atomicObj.val = it 
			if (localObj  != null)	localObj.val = it
		}
	}	
}
