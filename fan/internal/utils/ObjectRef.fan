using concurrent::AtomicRef
using afConcurrent::LocalRef

internal const class ObjectRef {
			const Str 			name
			const ServiceScope	scope
	private const AtomicRef? 	atomicObj
	private const LocalRef?		localObj
	private const Obj?			def
	override const Str 			toStr
	
	new make(LocalRef localRef, ServiceScope scope, Obj? val := null, Obj? def := null) {
		if (scope == ServiceScope.perApplication)
			this.atomicObj = AtomicRef()
		if (scope == ServiceScope.perThread)
			this.localObj = localRef
		
		this.val	= val
		this.def	= def
		this.name	= localRef.name
		this.scope	= scope
		this.toStr	= name
	}
	
	Obj? val {
		get {
			if (atomicObj != null)	return atomicObj.val ?: def
			if (localObj  != null)	return localObj.val  ?: def
			return null
		}
		set { 
			if (atomicObj != null)	atomicObj.val = it.toImmutable
			if (localObj  != null)	localObj.val  = it
		}
	}
	
	Void cleanUp() {
		localObj?.cleanUp
	}
}
