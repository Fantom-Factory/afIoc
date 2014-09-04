
** Meta info that defines a service 
internal const class ServiceDef {	
	const Str 			moduleId
	const Str 			serviceId
	const Type			serviceType
	const ServiceScope	scope	// TODO: -> serviceScope
	const Bool			noProxy	// FIXME
	const |->Obj|		serviceBuilder
	const Str			description

	private const Str 	unqualifiedServiceId

	new makeStandard(|This| f ) { 
		f(this)
		if (scope == ServiceScope.perApplication && !serviceType.isConst)
			throw IocErr(IocMessages.perAppScopeOnlyForConstClasses(serviceType))	
		unqualifiedServiceId = unqualify(serviceId)
	}

	new makeBuiltIn(|This| f) { 
		this.moduleId		= IocConstants.builtInModuleId
		this.scope			= ServiceScope.perApplication
		this.noProxy		= true

		f(this)
		
		if (serviceId == null)
			serviceId = serviceType.qname

		if (serviceBuilder == null)
			serviceBuilder = |->Obj| { 
				throw IocErr("Can not create BuiltIn service '$serviceId'") 
			}

		description = "$serviceId : BuiltIn Service"
		unqualifiedServiceId = unqualify(serviceId)
	}

	// FIXME kill me
	Bool proxiable() {
		// if we proxy a per 'perInjection' into an app scoped service, is it perApp or perThread!??
		// Yeah, exactly! Just don't allow it.
		!noProxy && serviceType.isMixin && (scope != ServiceScope.perInjection)
	}
	
	Bool matchesId(Str serviceId) {
		this.serviceId.equalsIgnoreCase(serviceId) || this.unqualifiedServiceId.equalsIgnoreCase(unqualify(serviceId))
	}
	
	override Str toStr() {
		description
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


internal class ServiceDefMutable {	// TODO: ServiceTempDef
	Str 			id
	Type 			type
	Obj				builderData	// type or method
	ServiceScope	scope
	ServiceProxy	proxy
	Str 			moduleId
	Bool			overridden

	new make(|This| in) { in(this) }
	
	override Str toStr() {
		// FIXME: add ctx for err msgs in ModuleDefImpl
		id
	}
	
	ServiceDef toServiceDef() {
		ServiceDef.makeStandard {
			it.moduleId			= this.moduleId
			it.serviceId		= this.id
			it.serviceType		= this.type
			it.scope			= this.scope
			it.noProxy			= proxy == ServiceProxy.never
			
			if (builderData is Type) {
				serviceImplType		:= (Type) builderData
				it.serviceBuilder	= ServiceBuilders.fromCtorAutobuild(it, serviceImplType)
				it.description		= "$serviceId : via Ctor Autobuild (${serviceImplType.qname})"
			}

			if (builderData is Method) {
				builderMethod		:= (Method) builderData
				it.serviceBuilder	= ServiceBuilders.fromBuildMethod(it, builderMethod)
				it.description		= "$serviceId : via Builder Method (${builderMethod.qname})"
			}
			
			if (this.overridden)
				it.description	+= " (Overridden)"
		}
	}
}


	
internal const mixin ServiceBuilders {
	
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
					return InjectionUtils.injectIntoFields(obj)
				}
			}			
		}.toImmutable
	}
}
