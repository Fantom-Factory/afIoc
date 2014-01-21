
** A helper class that coerces Objs to a given Type via 'fromXXX()' / 'toXXX()' ctors and methods. 
** This is mainly useful for convertint to and from Strs.
**  
** As a lot of repetition of types is expected for each 'TypeCoercer' the conversion methods are 
** cached.
** 
** @since 1.3.8
class TypeCoercer {
	private Str:|Obj->Obj|? cache	:= [:]
	
	** Returns 'true' if 'fromType' can be coerced to the given 'toType'.
	Bool canCoerce(Type fromType, Type toType) {
		coerceMethod(fromType, toType) != null
	}
	
	** Coerces the Obj to the given type. 
	** Coercion methods are looked up in the following order:
	**  1. toXXX()
	**  2. fromXXX()
	**  3. makeFromXXX() 
	Obj coerce(Obj value, Type toType) {
		meth := coerceMethod(value.typeof, toType)
		
		if (meth == null)
			throw IocErr(IocMessages.typeCoercionNotFound(value.typeof, toType))

		try {
			return meth(value)
		} catch (Err e) {
			throw IocErr(IocMessages.typeCoercionFail(value.typeof, toType), e)
		}
	}

	** Clears the lookup cache 
	Void clearCache() {
		cache.clear
	}
	
	private |Obj->Obj|? coerceMethod(Type fromType, Type toType) {
		key	:= "${fromType.qname}->${toType.qname}"
		return cache.getOrAdd(key) { lookupMethod(fromType, toType)  }
	}
	
	private |Obj->Obj|? lookupMethod(Type fromType, Type toType) {

		// check the basics first!
		if (fromType.fits(toType))
			return |Obj val -> Obj| { val }

		// first look for a 'toXXX()' instance method
		toName		:= "to${toType.name}" 
		toXxxMeth 	:= ReflectUtils.findMethod(fromType, toName, Obj#.emptyList, false, toType)
		if (toXxxMeth != null)
			return |Obj val -> Obj| { toXxxMeth.callOn(val, null) }

		// next look for a 'fromXXX()' static / ctor
		// see http://fantom.org/sidewalk/topic/2154
		fromName	:= "from${fromType.name}" 
		fromXxxMeth	:= ReflectUtils.findCtor(toType, fromName, [fromType])
		if (fromXxxMeth == null)
			fromXxxMeth = ReflectUtils.findMethod(toType, fromName, [fromType], true)
		if (fromXxxMeth != null)
			return |Obj val -> Obj| { fromXxxMeth.call(val) }
				
		// one last chance - try 'makeFromXXX()' ctors
		fromName	= "makeFrom${fromType.name}" 
		fromXxxMeth	= ReflectUtils.findCtor(toType, fromName, [fromType])
		if (fromXxxMeth == null)
			fromXxxMeth = ReflectUtils.findMethod(toType, fromName, [fromType], true)
		if (fromXxxMeth != null)
			return |Obj val -> Obj| { fromXxxMeth.call(val) }
		
		return null
	}
}
