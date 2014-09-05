
** Meta info that defines a service 
internal const class ServiceDef {	
	const Str 			serviceId
	const Type			serviceType
	const ServiceScope	serviceScope
	const Bool			noProxy	// FIXME proxy
	const |->Obj|		serviceBuilder
	const Str			description

	const Module?		module	// null for adhoc autobuilds and proxies

	private const Str 	unqualifiedServiceId
	private const Type 	serviceTypeNonNull

	new makeStandard(|This| f ) { 
		f(this)

		if (serviceScope == ServiceScope.perApplication && !serviceType.isConst)
			throw IocErr(IocMessages.perAppScopeOnlyForConstClasses(serviceType))

		if (serviceBuilder == null)
			serviceBuilder = |->Obj| { 
				throw IocErr("Can not create BuiltIn service '$serviceId'") 
			}

		unqualifiedServiceId	= unqualify(serviceId)
		serviceTypeNonNull		= serviceType.toNonNullable
	}

	Obj getService(Bool returnReal) {	// only proxy needs to get real
		module.service(this, returnReal, null)
	}
	
	Obj newInstance() {
		module.service(this, false, true)		
	}
	
	// FIXME proxy kill me
	Bool proxiable() {
		// if we proxy a per 'perInjection' into an app scoped service, is it perApp or perThread!??
		// Yeah, exactly! Just don't allow it.
		!noProxy && serviceType.isMixin && (serviceScope != ServiceScope.perInjection)
	}
	
	Bool matchesId(Str serviceId) {
		this.serviceId.equalsIgnoreCase(serviceId) || this.unqualifiedServiceId.equalsIgnoreCase(unqualify(serviceId))
	}

	Bool matchesType(Type serviceType) {
		serviceTypeNonNull.fits(serviceType.toNonNullable)
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


internal class SrvDef {
	Str				id
	Type?			type
	Str 			moduleId	// needed for err msgs

	Obj?			buildData	// type or method
	ServiceScope?	scope
	ServiceProxy?	proxy
	Bool			overridden
	Str?			overrideRef
	Bool			overrideOptional

	Bool			builtIn
	Str?			desc

	new make(|This| in) { in(this) }
	
	ServiceDef toServiceDef(Module module) {
		if (builtIn) {
			proxy		= ServiceProxy.never

			if (scope == null)
				scope	= ServiceScope.perApplication
			
			if (desc == null)
				desc = "$id : BuiltIn Service"
		}

		return ServiceDef.makeStandard {
			it.module			= module
			it.serviceId		= this.id
			it.serviceType		= this.type
			it.serviceScope		= this.scope
			it.noProxy			= proxy == ServiceProxy.never
			
			if (buildData is Type) {
				serviceImplType		:= (Type) buildData
				it.serviceBuilder	= ServiceBuilders.fromCtorAutobuild(it, serviceImplType)
				it.description		= "$serviceId : via Ctor Autobuild (${serviceImplType.qname})"
			} 
			
			else if (buildData is Method) {
				builderMethod		:= (Method) buildData
				it.serviceBuilder	= ServiceBuilders.fromBuildMethod(it, builderMethod)
				it.description		= "$serviceId : via Builder Method (${builderMethod.qname})"
			} 

			else		
				it.serviceBuilder	= buildData
			
			if (this.overridden)
				it.description	+= " (Overridden)"
			
			if (desc != null)
				it.description = desc
		}
	}

	Void applyOverride(SrvDef serviceOverride) {
		if (serviceOverride.type != null && !serviceOverride.type.fits(type))
			throw IocErr(IocMessages.serviceOverrideDoesNotFitServiceDef(id, serviceOverride.type, type))

		if (serviceOverride.buildData is Type && !((Type) serviceOverride.buildData).fits(type))
			throw IocErr(IocMessages.serviceOverrideDoesNotFitServiceDef(id, serviceOverride.buildData, type))
		
		if (serviceOverride.buildData != null)
			this.buildData = serviceOverride.buildData

		if (serviceOverride.scope != null)
			this.scope = serviceOverride.scope

		if (serviceOverride.proxy != null)
			this.proxy = serviceOverride.proxy

		this.overridden = true
	}

	override Str toStr() { id }
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
