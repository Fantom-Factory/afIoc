
** @since 1.3
internal const class PlasticMsgs {
	
	// ---- Err Messages --------------------------------------------------------------------------

	static Str nonConstTypeCannotSubclassConstType(Str typeName, Type superType) {
		"Non-const type ${typeName} can not subclass const type ${superType.qname}"
	}

	static Str constTypeCannotSubclassNonConstType(Str typeName, Type superType) {
		"Const type ${typeName} can not subclass non-const type ${superType.qname}"
	}

	static Str canOnlyExtendOneType(Str typeName, Type superType1, Type superType2) {
		"Currently, Plastic only supports extending ONE type - class ${typeName} : ${superType1.qname}, ${superType2.qname}"
	}

	static Str canOnlyExtendMixins(Str typeName, Type superType) {
		"Currently, Plastic only supports extending mixins - class ${typeName} : ${superType.qname}"
	}

	static Str superTypesMustBePublic(Str typeName, Type superType) {
		"Super types must be 'public' or 'protected' scope - class ${typeName} : ${superType.qname}"
	}

	static Str constTypesMustHaveConstFields(Str typeName, Type fieldType, Str fieldName) {
		"Const type ${typeName} must ONLY declare const fields - ${fieldType.qname} ${fieldName}"
	}

	static Str overrideMethodDoesNotBelongToSuperType(Method method, Type superType) {
		"Method ${method.qname} does not belong to super type ${superType.qname}"
	}

	static Str overrideMethodHasWrongScope(Method method) {
		"Method ${method.qname} must have 'public' or 'protected' scope"
	}

	static Str overrideMethodsMustBeVirtual(Method method) {
		"Method ${method.qname} must be virtual (or abstract)"
	}

}
