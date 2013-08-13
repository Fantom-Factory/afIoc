
** @since 1.3
internal const class PlasticMsgs {
	
	// ---- Err Messages --------------------------------------------------------------------------

	static Str nonConstTypeCannotSubclassConstType(Str typeName, Type superType) {
		"Non-const type ${typeName} can not subclass const type ${superType.qname}"
	}

	static Str constTypeCannotSubclassNonConstType(Str typeName, Type superType) {
		"Const type ${typeName} can not subclass non-const type ${superType.qname}"
	}

	static Str superTypesMustBePublic(Str typeName, Type superType) {
		"Super types must be 'public' or 'protected' scope - class ${typeName} : ${superType.qname}"
	}

	static Str constTypesMustHaveConstFields(Str typeName, Type fieldType, Str fieldName) {
		"Const type ${typeName} must ONLY declare const fields - ${fieldType.qname} ${fieldName}"
	}

	static Str overrideMethodDoesNotBelongToSuperType(Method method, Type[] superTypes) {
		"Method ${method.qname} does not belong to super types " + superTypes.map { it.qname }.join(", ")
	}

	static Str overrideMethodHasWrongScope(Method method) {
		"Method ${method.qname} must have 'public' or 'protected' scope"
	}

	static Str overrideMethodsMustBeVirtual(Method method) {
		"Method ${method.qname} must be virtual (or abstract)"
	}

	static Str overrideFieldDoesNotBelongToSuperType(Field field, Type[] superTypes) {
		"Field ${field.qname} does not belong to super type " + superTypes.map { it.qname }.join(", ")
	}

	static Str overrideFieldHasWrongScope(Field field) {
		"Field ${field.qname} must have 'public' or 'protected' scope"
	}

	static Str overrideMethodsCanNotHaveDefaultValues(Method method) {
		"Can not override methods with default parameter values : ${method.qname}"
	}

}
