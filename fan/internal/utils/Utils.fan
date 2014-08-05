
internal class Utils {
	
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
	
	static Err unwrap(IocErr err) {
		if (err.cause == null)
			return (Err) err
		return err.cause.typeof.fits(IocErr#) ? unwrap((IocErr) err.cause) : err.cause
	}
	
	static Obj cloneObj(Obj obj, |Field:Obj|? overridePlan := null) {
		plan := Field:Obj[:]
		obj.typeof.fields.each {
			value := it.get(obj)
			if (value != null)
				plan[it] = value
		}

		overridePlan?.call(plan)
		
		planFunc := Field.makeSetFunc(plan)
		return obj.typeof.method("make").call(planFunc)
	}
}
