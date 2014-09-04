using afBeanUtils

** As thrown by IoC
const class IocErr : Err {
	
	** A trace of IoC operations that led to the Err. 
	** A succinct and more informative stack trace if you will.
	const Str? operationTrace
	
	internal new make(Str msg := "", Err? cause := null, Str? opTrace := null) : super(msg, cause) {
		this.operationTrace = opTrace
	}
	
	override Str toStr() {
		opTrace := (cause == null) 
				? "${typeof.qname}: " 
				: (cause is IocErr ? "" : "${cause.typeof.qname}: ")
		opTrace += msg
		if (operationTrace != null && !operationTrace.isEmpty) {
			opTrace += "\nIoc Operation Trace:\n"
			operationTrace.splitLines.each |op, i| { 
				opTrace += ("  [${(i+1).toStr.justr(2)}] $op\n")
			}
			opTrace += "Stack Trace:"
		}
		return opTrace
	}
}

** Thrown when registry methods are invoked after it has been shutdown. 
** This has a dedicated Err class so it may be catered for explicitly.
@NoDoc	// Advanced use only
const class IocShutdownErr : IocErr {
	new make(Str msg, Err? cause := null, Str? opTrace := null) : super(msg, cause, opTrace) {}
}

@NoDoc
const class ServiceNotFoundErr : IocErr, NotFoundErr {
	override const Str[] availableValues
	
	new make(Str msg, Obj?[] availableValues, Err? cause := null) : super(msg, cause) {
		this.availableValues = availableValues.map { it?.toStr }.sort
	}
	
	override Str toStr() {
		NotFoundErr.super.toStr		
	}
}

** Thrown when an impossible condition occurs. You know when - we've all written comments like:
** 
** '// this should never happen...' 
@NoDoc	// Who cares?
const class WtfErr : Err {
	new make(Str msg, Err? cause := null) : super(msg, cause) {}
}
