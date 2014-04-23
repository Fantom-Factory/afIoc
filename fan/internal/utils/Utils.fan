
internal class Utils {

	static Str banner(Str heading) {
		title := "\n"
		title += Str<|   ___    __                 _____        _                  
		                / _ |  / /  _____  _____  / ___/__  ___/ /_________  __ __ 
		               / _  | / /_ / / -_|/ _  / / __// _ \/ _/ __/ _  / __|/ // / 
		              /_/ |_|/___//_/\__|/_//_/ /_/   \_,_/__/\__/____/_/   \_, /  
		              |>
		first := true
		while (!heading.isEmpty) {
			banner := heading.size > 52 ? heading[0..<52] : heading
			heading = heading[banner.size..-1]
			banner = first ? (banner.padl(52, ' ') + " /___/   \n") : (banner.padr(52, ' ') + "\n")
			title += banner
			first = false
		}
		title 	+= "\n"
		return title
	}
	
	static Obj:Obj? makeMap(Type keyType, Type valType) {
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
	
	static Err unwrap(Unwrappable err) {
		if (err.cause == null)
			return (Err) err
		return err.cause.typeof.fits(Unwrappable#) ? unwrap((Unwrappable) err.cause) : err.cause
	}
	
//	static Obj cloneObj(Obj obj, |Field:Obj|? overridePlan := null) {
//		plan := Field:Obj[:]
//		obj.typeof.fields.each {
//			value := it.get(obj)
//			if (value != null)
//				plan[it] = value
//		}
//
//		overridePlan.call(plan)
//		
//		planFunc := Field.makeSetFunc(plan)
//		return obj.typeof.method("make").call(planFunc)
//	}
}
