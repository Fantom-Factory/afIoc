
** Same as StandardServiceDef, but with defaults. Can't set them any other way.
** see http://fantom.org/sidewalk/topic/2148#c13906
internal const class BuiltInServiceDef : ServiceDef {

	override const Str 			moduleId
	override const Str 			serviceId
	override const Str 			unqualifiedServiceId
	override const Type			serviceType
	override const Type?		serviceImplType
	override const ServiceScope	scope
	override const Bool			noProxy
			 const |->Obj|		source
			 const Str?			description

	new make(|This| f) { 
		this.moduleId		= IocConstants.builtInModuleId
		this.scope			= ServiceScope.perApplication
		this.noProxy		= true

		f(this)
		
		if (serviceId == null)
			serviceId = serviceType.qname

		if (serviceImplType == null && source != null)
			serviceImplType = Type.find("${serviceType.qname}Impl", false) ?: serviceType
		
		if (source == null)
			source = |->Obj| { 
				throw IocErr("Can not create BuiltIn service '$serviceId'") 
			}

		unqualifiedServiceId = unqualify(serviceId)
	}

	override |->Obj| createServiceBuilder() {
		source
	}
	
	override Str toStr() {
		// serviceId is usually set *after* our defaults in the ctor, so we can't set desc above
		description ?: "'$serviceId' : Built In Service"
	}	
}
