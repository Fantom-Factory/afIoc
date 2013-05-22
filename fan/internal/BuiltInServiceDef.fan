
** Same as StandardServiceDef, but with defaults. Can't set them any other way.
** see http://fantom.org/sidewalk/topic/2148#c13906
internal const class BuiltInServiceDef : ServiceDef {

	override const Str 			moduleId
	override const Str 			serviceId
	override const Type			serviceType
	override const Type?		serviceImplType
	override const ServiceScope	scope
	override const Bool			noProxy
	const |InjectionCtx->Obj|	source
	const Str					description
	
	new make(|This| f) { 
		this.moduleId		= ServiceIds.builtInModuleId
		this.scope			= ServiceScope.perApplication
		this.noProxy		= true
		this.source 		= |InjectionCtx ctx->Obj| { throw IocErr("Can not create BuiltIn service '$serviceId'") }
		this.description	= "'$serviceId' : Built In Service"

		f(this)
	}

	override |InjectionCtx->Obj| createServiceBuilder() {
		source
	}
	
	override Str toStr() {
		description
	}	
}
