
internal const class StandardServiceDef : ServiceDef {
	
	override const Str 			moduleId
	override const Str 			serviceId
	override const Type			serviceType
	override const ServiceScope	scope
	
	const |InjectionCtx->Obj| 	source
	const Str	description
	
	new make(|This|? f := null) { 
		f?.call(this)
		
		if (scope == ServiceScope.perApplication && !serviceType.isConst)
			throw IocErr(IocMessages.perAppScopeOnlyForConstClasses(serviceType))			
	}
	
	override |InjectionCtx->Obj| createServiceBuilder() {
		source
	}
	
	override Str toStr() {
		description
	}
}
