using afConcurrent

** A helper class that coerces Objs to a given Type via 'fromXXX()' / 'toXXX()' ctors and methods. 
** This is mainly useful for converting to and from Strs.
**  
** As a lot of repetition of types is expected for each 'TypeCoercer' the conversion methods are 
** cached.
** 
** @since 1.3.8
const class TypeCoercer {
	private const AtomicMap cache	:= AtomicMap()
	
	** Returns 'true' if 'fromType' can be coerced to the given 'toType'.
	Bool canCoerce(Type fromType, Type toType) {
		if (fromType.name == "List" && toType.name == "List") 
			return coerceMethod(fromType.params["V"], toType.params["V"]) != null
		return coerceMethod(fromType, toType) != null
	}
	
	** Coerces the Obj to the given type. 
	** Coercion methods are looked up in the following order:
	**  1. toXXX()
	**  2. fromXXX()
	**  3. makeFromXXX() 
	Obj coerce(Obj value, Type toType) {

		if (value.typeof.name == "List" && toType.name == "List") {
			toListType 	:= toType.params["V"]
			toList 		:= toListType.emptyList.rw
			((List) value).each {
				toList.add(coerce(it, toListType))
			}
			return toList
		}

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
		return cache.getOrAdd(key) { lookupMethod(fromType, toType) }
	}
	
	private static |Obj->Obj|? lookupMethod(Type fromType, Type toType) {

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
		fromXxxMeth	:= ReflectUtils.findMethod(toType, fromName, [fromType], true)
		if (fromXxxMeth != null)
			return (|Obj val -> Obj| { fromXxxMeth.call(val) }).toImmutable
		fromXxxCtor := ReflectUtils.findCtor(toType, fromName, [fromType])
		if (fromXxxCtor != null)
			return (|Obj val -> Obj| { fromXxxCtor.call(val) }).toImmutable
				
		// one last chance - try 'makeFromXXX()' ctors
		makefromName	:= "makeFrom${fromType.name}" 
		makeFromXxxMeth	:= ReflectUtils.findMethod(toType, makefromName, [fromType], true)
		if (makeFromXxxMeth != null)
			return |Obj val -> Obj| { makeFromXxxMeth.call(val) }
		makeFromXxxCtor := ReflectUtils.findCtor(toType, makefromName, [fromType])
		if (makeFromXxxCtor != null)
			return |Obj val -> Obj| { makeFromXxxCtor.call(val) }
		
		return null
	}
}
