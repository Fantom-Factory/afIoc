using afBeanUtils::NotFoundErr

** (Service) - Contribute to override previously defined services. Use to override production services with test 
** versions, or to replace 3rd party services with your own implementation. 
** 
** Use the service Id to specify the original service to override. The contribution may one of:
** 
**  - 'Type': The type is autobuilt by IoC. (Useful for non-const services.)
**  - '|->Obj|': The func is called to create the service. (Useful for non-const services.)
**  - 'Obj': The actual implementation.
**  
** For example, to override the 'PieAndChips' service with an instance of 'PieAndMash': 
** 
** pre>
**   static Void bind(ServiceBinder binder) {
**     binder.bind(PieAndChips#)  // the original service
**   }
** 
**   @Contribute { serviceType=ServiceOverrides# }
**   static Void contributeServiceOverrides(Configuration conf) {
**     conf["myPod::PieAndChips"] = PieAndMash()
**   }
** <pre
**
** Or the contribution could also one of be:
** 
**   conf["myPod::PieAndChips"] = PieAndMash#
**   conf["myPod::PieAndChips"] = |->Obj| { return PieAndMash() }
**   conf["myPod::PieAndChips"] = PieAndMash()
** 
** Obviously, the overriding type ( 'PieAndMash' ) has to fit the original service type ( 'PieAndChips' ).
**
** Taking advantage of Type Coercion, you can use the service Type as the key:
** 
** pre>
**   @Contribute { serviceType=ServiceOverrides# }
**   static Void contributeServiceOverrides(Configuration conf) {
**     conf[PieAndChips#] = PieAndMash()
**   }
** <pre
** 
** Note you can only override the implementation, not the definition. 
** Meaning you can not change a service's id, scope or proxy settings.
** 
** Also note that (using your override Id) someone else can override *your* override!
** 
** @since 1.2
** 
** @uses Configuration of 'Str:Obj' (serviceId:overrideImpl)
@Deprecated
const mixin ServiceOverrides {
	
	@NoDoc
	abstract Str:|->Obj| overrides()
}



** @since 1.2.0
internal const class ServiceOverridesImpl : ServiceOverrides {
	
	@Inject 
	private const Registry 	registry
	private const Str:Obj	serviceOverrides
	
	new make(Str:Obj serviceOverrides, |This|in) { 
		in(this) 
		this.serviceOverrides = serviceOverrides
	}
	
	override Str:|->Obj| overrides() {
		serviceOverrides.map |buildObj, id| {
			existingDef := ((ObjLocator) registry).serviceDefById(id)
			if (existingDef == null)
				throw ServiceNotFoundErr(IocMessages.serviceOverrideDoesNotExist(id), ((RegistryImpl) registry).stats.keys)

			builder := (|->Obj|?) null

			if (buildObj is |->Obj|) {
				builder = buildObj
			}

			if (buildObj is Type) {
				overrideType := (Type) buildObj	
				if (!overrideType.fits(existingDef.serviceType))
					throw IocErr(IocMessages.serviceOverrideDoesNotFitServiceDef(id, overrideType, existingDef.serviceType))
				builder = |->Obj| { registry.autobuild(buildObj) }
			}

			if (builder == null) {
				if (!buildObj.typeof.fits(existingDef.serviceType))
					throw IocErr(IocMessages.serviceOverrideDoesNotFitServiceDef(id, buildObj.typeof, existingDef.serviceType))
				builder = |->Obj| { buildObj }
			}
			
			try 	builder.toImmutable
			catch	throw IocErr(IocMessages.serviceOverrideNotImmutable(id))
			return	builder.toImmutable
		}
	}
}
