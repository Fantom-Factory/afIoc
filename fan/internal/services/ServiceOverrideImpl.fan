
internal const class ServiceOverrideImpl : ServiceOverride {
	
	private const Str:Obj overrides
	
	new make(Str:Obj overrides, RegistryImpl registry) {
		overrides.each |service, id| {			
			existingDef := registry.serviceDefById(id)
			if (existingDef == null)
				throw IocErr(IocMessages.serviceOverrideDoesNotExist(id, service.typeof))

			if (!service.typeof.fits(existingDef.serviceType))
				throw IocErr(IocMessages.serviceOverrideDoesNotFitServiceDef(id, service.typeof, existingDef.serviceType))
			
			if (!service.isImmutable)
				throw IocErr(IocMessages.serviceOverrideNotImmutable(id, service.typeof))
		}
		
		this.overrides = overrides
	}
	
	override Obj? getOverride(Str serviceId) {
		overrides[serviceId]
	}
}