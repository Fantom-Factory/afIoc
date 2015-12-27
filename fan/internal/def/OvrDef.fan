
@Js
internal class OvrDef {
	Type 			moduleId	// see ErrMsgs.registry_serviceAlreadyDefined()
	Str?			serviceId
	Type?			serviceType

	|Scope->Obj?|?	builder
	Str[]?			aliases
	Type[]?			aliasTypes
	Str[]?			scopes

	Bool			autobuild
	Type?			implType
	Obj?[]?			ctorArgs
	[Field:Obj?]?	fieldVals

	Str?			overrideId
	Bool			optional

	|Str, Type|?	gotService
	
	new make(|This|in) { in(this) }

	
	
	override Str toStr() { serviceId ?: (serviceType?.qname ?: "ID not set") }
}
