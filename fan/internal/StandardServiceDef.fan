using concurrent

internal const class StandardServiceDef : ServiceDef {
	
	override const Str 			moduleId
	override const Str 			serviceId
	override const Str 			unqualifiedServiceId
	override const Type			serviceType
//	override const Type?		serviceImplType
	override const ServiceScope	scope
	override const Bool			noProxy
			 const AtomicRef	serviceBuilderRef
			 const Str			description
			 const AtomicBool	overriddenRef

	new make(|This|? f := null) { 
		serviceBuilderRef 	= AtomicRef()
		overriddenRef		= AtomicBool(false) 
		f?.call(this)
		if (scope == ServiceScope.perApplication && !serviceType.isConst)
			throw IocErr(IocMessages.perAppScopeOnlyForConstClasses(serviceType))	
		unqualifiedServiceId = unqualify(serviceId)
	}

	override |->Obj| serviceBuilder() {
		serviceBuilderRef.val
	}
	
	override Void overrideBuilder(|->Obj| builder) {
		serviceBuilderRef.val = builder.toImmutable
		overriddenRef.val = true
	}
	
	override Str toStr() {
		overriddenRef.val ? "${serviceId} : Overridden" : description
	}
}
