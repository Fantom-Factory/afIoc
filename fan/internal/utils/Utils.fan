
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

	** Unwrap afIoc Errs to find the root cause. 
	**  - if an afIoc Err, throw a new afIoc Err (with NO cause) keeping the orig msg and opTrace.
	**  - if NOT an afIoc Err, wrap it in a new afIoc Err with the opTrace.
	** This adds extra opTrace info to all non-afIoc Errs and reduces the number of stack frames
	** on all internal afIoc Errs.
	** @see http://fantom.org/sidewalk/topic/2147
	static Obj? stackTraceFilter(|->Obj?| func) {
		try {
			return func.call
		} catch (IocErr iocErr) {
			unwrapped := unwrap(iocErr)

			// throw a new afIoc Err (with NO cause) keeping the orig msg and opTrace. 
			if (unwrapped is IocErr)
				throw IocErr(iocErr.msg, null, iocErr.operationTrace)
			
			// wrap root err in an afIoc Err, giving extra opTrace info and any helpful ioc Err 
			throw IocErr(iocErr.msg, unwrapped, iocErr.operationTrace)
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
