
internal class Utils {
	
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

//	** Stoopid F4 thinks the 'facet' method is a reserved word!
//	static Bool hasFacet(Slot slot, Type annotation) {
//		slot.facets.find |fac| { 
//			fac.typeof == annotation
//		} != null		
//	}

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
	
}
