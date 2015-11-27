
** Passed to [DependencyProviders]`DependencyProvider` to give contextual injection information.
@Js
mixin InjectionCtx {
	
	** The id of the service (if any) that is being created. 
	abstract Str?		serviceId()

	** The object that will receive the injection.
	abstract Obj?		targetInstance()
	
	** The 'Type' of object that will receive the injection. 
	** This is the parent 'Type' that contains the field or method.
	** Is 'null' when resolving parameters for a pure / non-method func.
	abstract Type?		targetType()

	** The field to be injected. Only available for field injection. 
	abstract Field?		field()

	** The method to be injected. Only available for some func injection.
	** 
	** Convenience for 'func?.method'. 
	Method?	method()	{ func?.method }

	** The func to be injected. Only available for func injection. 
	abstract Func?		func()

	** Provided arguments to call the func with. 
	abstract Obj?[]?	funcArgs()
	
	** The func 'Param' to be injected. Only available for func injection. 
	abstract Param?		funcParam()

	** The index of the func 'Param' to be injected. Only available for func injection. 
	abstract Int?		funcParamIndex()

	** Returns 'true' if performing field injection.
	Bool isFieldInjection() {
		field != null 
	}

	** Returns 'true' if performing func (or method) injection.
	** 
	** Convenience for 'func != null'. 
	Bool isFuncInjection() {
		func != null 
	}

	** Returns 'true' if performing method injection.
	** 
	** Convenience for 'func != null && func.method != null'. 
	Bool isMethodInjection() {
		func != null && func.method != null
	}

	** Returns 'true' if the first parameter of the func should be a 'Map' or 'List' service configuration.
	virtual Bool funcTakesServiceConfig() {
		serviceId != null &&
		func != null && method != null &&
		(method.isCtor || method.hasFacet(Build#)) &&
		(func.params.first?.type?.name == "List" || func.params.first?.type?.name == "Map")
	}

	** Returns the index into 'funcArgs' should it be applicable, 'null' otherwise. 
	** This takes into account any service configuration injection (if applicable).
	Int? funcArgIndex() {
		if (!isFuncInjection || funcArgs == null)
			return null
		if (funcTakesServiceConfig && funcParamIndex == 0)
			return null
		funcArgIndex := funcTakesServiceConfig ? funcParamIndex - 1 : funcParamIndex
		return funcArgIndex >= funcArgs.size ? null : funcArgIndex
	}

	** Returns 'true' if injecting a 'Map' or 'List' service configuration.
	Bool isFuncArgServiceConfig() {
		funcTakesServiceConfig && funcParamIndex == 0
	}

	** Returns 'true' if an argument has been provided for this func parameter injection.
	Bool isFuncArgProvided() {
		funcArgIndex != null
	}

	** Returns 'true' if injecting a ctor it-block
	Bool isFuncArgItBlock() {
		func != null && method != null &&
		method.isCtor &&
		funcParamIndex == func.params.size - 1 &&
		funcParam.type.toNonNullable.fits(|This|#)		
	}

	** Returns 'true' if the func argument has been reserved by system providers; namely if the parameter is:
	**  - service configuration
	**  - a provider func argument
	**  - a ctor it-block 
	Bool isFuncArgReserved() {
		isFuncArgServiceConfig || isFuncArgProvided || isFuncArgItBlock
	}
	
	@NoDoc
	override Str toStr() {
		if (isFieldInjection)
			return "Field Injection: ${field.qname}"
		if (isMethodInjection)
			return "Method Injection: ${funcParam.type.qname} into ${method.qname}"
		if (isFuncInjection)
			return "Func Injection: ${funcParam.type.qname} into ${func.typeof.signature}"
		return "Unknown Injection"
	}
}

@Js
internal class InjectionCtxImpl : InjectionCtx {
	
	override Str?		serviceId
	override Obj?		targetInstance
	override Type?		targetType
	override Field?		field
	override Func?		func
	override Obj?[]?	funcArgs
	override Param?		funcParam
	override Int?		funcParamIndex
	override Bool 		funcTakesServiceConfig

	@NoDoc
	new make(|This|? in := null) {
		in?.call(this)
		
		funcTakesServiceConfig = 
			serviceId != null &&
			func != null && method != null &&
			(method.isCtor || method.hasFacet(Build#)) &&
			(func.params.first?.type?.name == "List" || func.params.first?.type?.name == "Map")
	}
}
