
internal class Utils {

	static Str banner(Str heading) {
		title	:= "$heading /___/   "
		title 	= title.padl(61, ' ')
		title = "   ___    __                 _____        _                  
		           / _ |  / /  _____  _____  / ___/__  ___/ /_________  __ __ 
		          / _  | / /_ / / -_|/ _  / / __// _ \\/ _/ __/ _  / __|/ // / 
		         /_/ |_|/___//_/\\__|/_//_/ /_/   \\_,_/__/\\__/____/_/   \\_, /  \n" + title
		title 	+= "\n\n"
		return title
	}
	
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

	** @see http://fantom.org/sidewalk/topic/2147
	static Obj? stackTraceFilter(|->Obj?| func) {
		try {
			return func.call
		} catch (OpTrackerErr opErr) {
			throw IocErr(opErr.msg, unwrap(opErr))
		} catch (IocErr iocErr) {
			throw IocErr(iocErr.msg, unwrap(iocErr))
		}
	}
	
	private static Err? unwrap(Unwrappable err) {
		(err.cause?.typeof?.fits(Unwrappable#) ?: false) ? unwrap((Unwrappable) err.cause) : err.cause
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
}
