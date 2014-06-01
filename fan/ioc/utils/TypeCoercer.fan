
@NoDoc @Deprecated { msg="Use afBeanUtils::TypeCoercer instead" }
const class TypeCoercer {
	private const CachingTypeCoercer typeCoercer := CachingTypeCoercer()
	
	Bool canCoerce(Type fromType, Type toType) {
		typeCoercer.canCoerce(fromType, toType)
	}
	
	Obj? coerce(Obj? value, Type toType) {
		typeCoercer.coerce(value, toType)
	}

	Void clearCache() {
		typeCoercer.clear
	}	
}
