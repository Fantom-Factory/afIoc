
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

	** Will be 'null' if built by a builder method 
	abstract Type? serviceImplType()

	abstract ServiceScope scope()

	abstract Bool noProxy()
	
	
	static |InjectionCtx ctx->Obj| fromBuildMethod(ServiceDef serviceDef, Method method) {
		|InjectionCtx ctx->Obj| {
				ctx.track("Creating Service '$serviceDef.serviceId' via a builder method '$method.qname'") |->Obj| {
					IocHelper.doLogServiceCreation(ModuleDefImpl#, "Creating Service '$serviceDef.serviceId'")
					return ctx.withProvider(ConfigProvider(ctx, serviceDef, method)) |->Obj?| {
						return InjectionUtils.callMethod(ctx, method, null)
					}
				}
		}
	}
	
	static |InjectionCtx ctx->Obj| fromCtorAutobuild(ServiceDef serviceDef, Type serviceImplType) {
		|InjectionCtx ctx->Obj| {
			ctx.track("Creating Serivce '$serviceDef.serviceId' via a standard ctor autobuild") |->Obj| {
				IocHelper.doLogServiceCreation(ServiceBinderImpl#, "Creating Service '$serviceDef.serviceId'")
				ctor := InjectionUtils.findAutobuildConstructor(ctx, serviceImplType)
				
				return ctx.withProvider(ConfigProvider(ctx, serviceDef, ctor)) |->Obj?| {
					obj := InjectionUtils.createViaConstructor(ctx, ctor, serviceImplType, Obj#.emptyList)
					InjectionUtils.injectIntoFields(ctx, obj)
					return obj
				}
			}			
		}
	}
}
