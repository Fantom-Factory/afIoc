
** Override a defined service with your own implementation. 
** 
** pre>
**   static Void bind(ServiceBinder binder) {
**     binder.bindImpl(PieAndChips#).withId("dinner")
**   }
** 
**   @Contribute
**   static Void contributeServiceOverride(MappedConfig config) {
**     config.addMapped("dinner", config.autobuild(PieAndMash#))
**   }
** <pre
**
** Note at present you can not override `perThread` scoped services and non-const (not immutable) 
** services. 
**  
** @since 1.2
** @uses MappedConfig of Str:Obj (serviceId:overrideImpl)
// Override perThread services should be automatic when proxies are added.
// TODO: Registry.autobuild should create proxies
const mixin ServiceOverride {
	
	abstract Obj? getOverride(Str serviceId)

}

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