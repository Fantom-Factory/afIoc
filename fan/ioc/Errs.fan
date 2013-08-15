
** Indicates the Err has a more interesting cause
@NoDoc
mixin Unwrappable {
	abstract Err? cause()
}

** As thrown by IoC
const class IocErr : Err, Unwrappable {
	
	const Str? operationsTrace
	
	internal new make(Str msg := "", Err? cause := null, Str? opTrace := null) : super(msg, cause) {
		this.operationsTrace = opTrace
	}
	
	override Str toStr() {
		opTrace := (cause == null) ? typeof.qname : (cause is IocErr ? "" : cause.typeof.qname + ": ")
		opTrace += msg
		if (operationsTrace != null) {
			opTrace += "Operations trace:\n"
			opTrace += operationsTrace
		}
		return opTrace
	}
}

** A generic helper Err thrown when a value is not found in an expected list of values.
** 
** This purposely does not extend `IocErr` so it may be freely used by other frameworks
const class NotFoundErr : Err {
	const Str[] values
	
	new make(Str msg, Obj?[] values, Err? cause := null) : super(msg + availableValues(values), cause) {
		this.values = values.exclude { it == null }.map { it.toStr }
	}

	Str availableValues(Obj?[] values) {
		vals := values.exclude { it == null }.map { it.toStr }.join(", ")
		return " Available values = ${vals}"
	}
}

** Thrown when an impossible condition occurs. You know when - we've all written comments like:
** 
** '// this should never happen...' 
const class WtfErr : Err {
	new make(Str msg, Err? cause := null) : super(msg, cause) {}
}
