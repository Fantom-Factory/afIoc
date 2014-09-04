
internal class ServiceDefMutable {

	Str 			serviceId
	Type 			serviceType
	|->Obj|			serviceBuilder
	ServiceScope	scope
	ServiceProxy	proxy
	Str 			moduleId

	private Str 	unqualifiedServiceId

	new make(|This| in) { in(this) }
	
//	Bool proxiable() {
//		// if we proxy a per 'perInjection' into an app scoped service, is it perApp or perThread!??
//		// Yeah, exactly! Just don't allow it.
//		proxy != ServiceProxy.never && serviceType.isMixin && (scope != ServiceScope.perInjection)
//	}
	
	Bool matchesId(Str serviceId) {
		this.serviceId.equalsIgnoreCase(serviceId) || this.unqualifiedServiceId.equalsIgnoreCase(unqualify(serviceId))
	}
	
	override Str toStr() {
		serviceId
	}
	
	override Int hash() {
		serviceId.hash
	}

	override Bool equals(Obj? obj) {
		serviceId == (obj as ServiceDef)?.serviceId
	}
	
	private static Str unqualify(Str id) {
		id.contains("::") ? id[(id.index("::")+2)..-1] : id
	}	
}



**
** Meta info that defines a service 
** 
internal const mixin ServiceDef {

	** Returns a factory func that creates the service implementation
	abstract |->Obj| serviceBuilder()

	abstract Void overrideBuilder(|->Obj| builder)

	** Returns the service id, which is usually the unqualified service type name.
	abstract Str serviceId()

	abstract Str unqualifiedServiceId()

	** Returns the id of the module this service was defined in
	abstract Str moduleId()
	
	** Returns the service type, either the mixin or impl type depending on how it was defined.
	abstract Type serviceType()

	abstract ServiceScope scope()

	abstract Bool noProxy()

	Bool proxiable() {
		// if we proxy a per 'perInjection' into an app scoped service, is it perApp or perThread!??
		// Yeah, exactly! Just don't allow it.
		!noProxy && serviceType.isMixin && (scope != ServiceScope.perInjection)
	}
	
	Bool matchesId(Str serviceId) {
		this.serviceId.equalsIgnoreCase(serviceId) || this.unqualifiedServiceId.equalsIgnoreCase(unqualify(serviceId))
	}
	
	override Str toStr() {
		serviceId
	}
	
	override Int hash() {
		serviceId.hash
	}

	override Bool equals(Obj? obj) {
		serviceId == (obj as ServiceDef)?.serviceId
	}
	
	protected static Str unqualify(Str id) {
		id.contains("::") ? id[(id.index("::")+2)..-1] : id
	}
	
	static |->Obj| fromBuildMethod(ServiceDef serviceDef, Method method, Obj? instance := null, Obj[]? args := null) {
		|->Obj| {
			InjectionTracker.track("Creating Service '$serviceDef.serviceId' via a builder method '$method.qname'") |->Obj| {
				objLocator := InjectionTracker.peek.objLocator
				
				// config is a very special method argument, as it's optional and if required, we 
				// use the param to generate the value
				return InjectionTracker.withConfigProvider(ConfigProvider(objLocator, serviceDef, method)) |->Obj?| {
					return InjectionUtils.callMethod(method, instance, args)
				}
			}
		}.toImmutable
	}
	
	static |->Obj| fromCtorAutobuild(ServiceDef serviceDef, Type serviceImplType) {
		|->Obj| {
			InjectionTracker.track("Creating Serivce '$serviceDef.serviceId' via a standard ctor autobuild") |->Obj| {
				objLocator := InjectionTracker.peek.objLocator
				ctor := InjectionUtils.findAutobuildConstructor(serviceImplType)
				
				// config is a very special method argument, as it's optional and if required, we 
				// use the param to generate the value
				return InjectionTracker.withConfigProvider(ConfigProvider(objLocator, serviceDef, ctor)) |->Obj?| {
					obj := InjectionUtils.createViaConstructor(ctor, serviceImplType, Obj#.emptyList, null)
					InjectionUtils.injectIntoFields(obj)
					return obj
				}
			}			
		}.toImmutable
	}
}
