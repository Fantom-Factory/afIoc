
internal class Utils {

	static Obj:Obj makeMap(Type keyType, Type valType) {
		mapType := Map#.parameterize(["K":keyType, "V":valType])
		return keyType.fits(Str#) ? Map.make(mapType) { caseInsensitive = true } : Map.make(mapType) { ordered = true }
	}
	
	static Log getLog(Type type) {
//		Log.get(type.pod.name + "." + type.name)
		type.pod.log
	}

	static Void setLoglevel(LogLevel logLevel) {
		Utils#.pod.log.level = logLevel
	}

	static Void setLoglevelDebug() {
		setLoglevel(LogLevel.debug)
	}

	static Void setLoglevelInfo() {
		setLoglevel(LogLevel.info)
	}
	
	static Void debugOperation(|->| operation) {
		setLoglevel(LogLevel.debug)
		try {
			operation()
		} finally {
			setLoglevel(LogLevel.info)
		}
	}

	** Stoopid F4 thinks the 'facet' method is a reserved word!
	** 'hasFacet' is available on Type.
	static Facet getFacetOnType(Type type, Type annotation) {
		if (!annotation.isFacet)
			throw Err("$annotation is not a facet!")
		return type.facets.find |fac| { 
			fac.typeof == annotation
		} ?: throw Err("Facet $annotation.qname not found on $type.qname")
	}

	** Stoopid F4 thinks the 'facet' method is a reserved word!
	** 'hasFacet' is available on Slot.
	static Facet getFacetOnSlot(Slot slot, Type annotation) {
		if (!annotation.isFacet)
			throw Err("$annotation is not a facet!")
		return slot.facets.find |fac| { 
			fac.typeof == annotation
		} ?: throw Err("Facet $annotation.qname not found on $slot.qname")
	}

	static Obj?[] toParamList( 
		Obj? a := null, Obj? b := null, Obj? c := null, Obj? d := null,
		Obj? e := null, Obj? f := null, Obj? g := null, Obj? h := null) {
		params := [a, b, c, d, e, f, g, h]
		// remove nulls from the end of the list
		while (!params.isEmpty && params.peek == null)
			params.pop
		return params
	}
}
