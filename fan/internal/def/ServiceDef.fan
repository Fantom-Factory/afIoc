
**
** Meta info that defines a service 
** 
internal const mixin ServiceDef {

	** Returns a factory func that creates the service implementation
	abstract |InjectionCtx->Obj| createServiceBuilder()

	** Returns the service id, which is usually the unqualified service type name.
	abstract Str serviceId()

	** Returns the id of the module this service was defined in
	abstract Str moduleId()
	
	** Returns the service type, either the mixin or implementation type depending on how it was 
	** defined.
	abstract Type serviceType()

	** Only actually needed by the 'ctorFieldInjector'!
	** Will be 'null' if built by a builder method 
	abstract Type? serviceImplType()

	abstract ServiceScope scope()

	abstract Bool noProxy()

	Bool proxiable() {
		// if we proxy a per 'perInjection' into an app scoped service, is it perApp or perThread!??
		// Yeah, exactly! Just don't allow it.
		!noProxy && serviceType.isMixin && (scope != ServiceScope.perInjection)
	}
	
	static |InjectionCtx->Obj| fromBuildMethod(ServiceDef serviceDef, Method method) {
		|InjectionCtx ctx->Obj| {
			InjectionCtx.track("Creating Service '$serviceDef.serviceId' via a builder method '$method.qname'") |->Obj| {
				ctx.objLocator.logServiceCreation(ModuleDefImpl#, "Creating Service '$serviceDef.serviceId'")
				
				// config is a very special method argument, as it's optional and if required, we 
				// use the param to generate the value
				return InjectionCtx.withProvider(ConfigProvider(ctx, serviceDef, method)) |->Obj?| {
					return InjectionUtils.callMethod(ctx, method, null, Obj#.emptyList)
				}
			}
		}
	}
	
	static |InjectionCtx->Obj| fromCtorAutobuild(ServiceDef serviceDef, Type serviceImplType) {
		|InjectionCtx ctx->Obj| {
			InjectionCtx.track("Creating Serivce '$serviceDef.serviceId' via a standard ctor autobuild") |->Obj| {
				InjectionCtx.peek.objLocator.logServiceCreation(ServiceBinderImpl#, "Creating Service '$serviceDef.serviceId'")
				ctor := InjectionUtils.findAutobuildConstructor(ctx, serviceImplType)
				
				// config is a very special method argument, as it's optional and if required, we 
				// use the param to generate the value
				return InjectionCtx.withProvider(ConfigProvider(ctx, serviceDef, ctor)) |->Obj?| {
					obj := InjectionUtils.createViaConstructor(ctx, ctor, serviceImplType, Obj#.emptyList)
					InjectionUtils.injectIntoFields(ctx, obj)
					return obj
				}
			}			
		}
	}
}
