
// in IoC, currently just used for TypeCoercer
internal class ReflectUtils {
	private new make() { }

	static Field? findField(Type type, Str fieldName, Type fieldType) {
		// 'fields()' returns inherited slots, 'field(name)' does not
		return type.fields.find |field| {
			if (field.name != fieldName) 
				return false
			return fits(field.type, fieldType)
		}
	}
	
	static Method? findCtor(Type type, Str ctorName, Type[] params := [,]) {
		// 'methods()' returns inherited slots, 'method(name)' does not
		return type.methods.find |method| {
			if (!method.isCtor) 
				return false
			if (method.name != ctorName) 
				return false
			return (paramTypesFitMethodSignature(params, method))
		}
	}

	static Method? findMethod(Type type, Str name, Type[] params := [,], Bool isStatic := false, Type? returnType := null) {
		// 'methods()' returns inherited slots, 'method(name)' does not
		return type.methods.find |method| {
			if (method.isCtor) 
				return false
			if (method.name != name) 
				return false
			if (method.isStatic != isStatic) 
				return false
			if (returnType != null && !fits(method.returns, returnType))
				return false
			return (paramTypesFitMethodSignature(params, method))
		}
	}

	static Bool paramTypesFitMethodSignature(Type?[] params, Method? method) {
		return method.params.all |methodParam, i->Bool| {
			if (i >= params.size)
				return methodParam.hasDefault
			if (params[i] == null)
				return methodParam.type.isNullable
			return fits(params[i], methodParam.type)
		}
	}
		
	** A replacement for 'Type.fits()' that take into account type inference for Lists and Maps.
	** 
	** Returns 'true' if 'typeA' *fits into* 'typeB'.  
	static Bool fits(Type? typeA, Type? typeB) {
		if (typeA == typeB)					return true
		if (typeA == null || typeB == null)	return false
		
		if (typeA.name == "List" && typeB.name == "List")
			return paramFits(typeA, typeB, "V")
			
		if (typeA.name == "Map" && typeB.name == "Map")
			return paramFits(typeA, typeB, "K") && paramFits(typeA, typeB, "V")
			
		return typeA.fits(typeB)
	}

	private static Bool paramFits(Type? typeA, Type? typeB, Str key) {
		paramTypeA := typeA.params[key] ?: Obj?#
		paramTypeB := typeB.params[key] ?: Obj?#
		return (paramTypeA.fits(paramTypeB) || paramTypeB.fits(paramTypeA))
	}		
}
