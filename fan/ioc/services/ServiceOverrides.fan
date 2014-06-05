using afBeanUtils::NotFoundErr

@NoDoc @Deprecated { msg="Use ServiceOverrides instead" }
const mixin ServiceOverride {
	abstract Obj? getOverride(Str serviceId)
}

** (Service) - Contribute to override previously defined services. Use to override production services with test 
** versions, or to replace 3rd party services with your own implementation. 
** 
** Use the service Id to specify the original service to override, and pass in the override instance. For example, 
** to override the 'PieAndChips' service with an instance of 'PieAndMash': 
** 
** pre>
**   static Void bind(ServiceBinder binder) {
**     binder.bind(PieAndChips#)
**   }
** 
**   @Contribute { serviceType=ServiceOverrides# }
**   static Void contributeServiceOverrides(MappedConfig conf) {
**     conf["myPod::PieAndChips"] = conf.autobuild(PieAndMash#)
**   }
** <pre
**
** Or taking advantage of Type Coercion, you can use the Type as the key:
** 
** pre>
**   @Contribute { serviceType=ServiceOverrides# }
**   static Void contributeServiceOverrides(MappedConfig conf) {
**     conf[PieAndChips#] = conf.autobuild(PieAndMash#)
**   }
** <pre
** 
** Obviously, the overriding class has to fit the original service type.
** 
** Note at present you can not override `perThread` scoped services and non-const (not immutable) 
** services. 
**  
** @since 1.2
** 
** @uses MappedConfig of 'Str:Obj' (serviceId:overrideImpl)
const mixin ServiceOverrides : ServiceOverride {
	
	@NoDoc
	override abstract Obj? getOverride(Str serviceId)
}



** @since 1.2.0
internal const class ServiceOverridesImpl : ServiceOverrides {
	
	private const Str:Obj overrides
	
	new make(Str:Obj overrides, Registry registry) {
		overrides.each |service, id| {			
			existingDef := ((ObjLocator) registry).serviceDefById(id)
			if (existingDef == null)
				throw OverrideNotFoundErr(IocMessages.serviceOverrideDoesNotExist(id, service.typeof), overrides.keys)

			if (!service.typeof.fits(existingDef.serviceType))
				throw IocErr(IocMessages.serviceOverrideDoesNotFitServiceDef(id, service.typeof, existingDef.serviceType))
			
			if (!service.isImmutable)
				throw IocErr(IocMessages.serviceOverrideNotImmutable(id, service.typeof))
		}
		this.overrides = overrides
	}
	
	override Obj? getOverride(Str serviceId) {
		overrides[serviceId] ?: overrides[ServiceDef.unqualify(serviceId)] 
	}
}

@NoDoc
const class OverrideNotFoundErr : IocErr, NotFoundErr {
	override const Str[] availableValues
	
	new make(Str msg, Obj?[] availableValues, Err? cause := null) : super(msg, cause) {
		this.availableValues = availableValues.map { it?.toStr }.sort
	}
	
	override Str toStr() {
		NotFoundErr.super.toStr		
	}
}