using afBeanUtils

** As thrown by IoC.
const class IocErr : Err {
	
	** A trace of IoC operations that led to the Err. 
	** A succinct and more informative stack trace if you will.
	const Str? operationTrace
	
	internal new make(Str msg := "", Err? cause := null, Str? opTrace := null) : super(msg, cause) {
		this.operationTrace = opTrace
	}
	
	@NoDoc
	override Str toStr() {
		opTrace := causeStr
		opTrace += opTraceStr
		opTrace += "Stack Trace:"
		return opTrace
	}
	
	@NoDoc
	protected Str causeStr() {
		opTrace := (cause == null) 
				? "${typeof.qname}: " 
				: (cause is IocErr ? "" : "${cause.typeof.qname}: ")
		opTrace += msg		
		return opTrace
	}

	@NoDoc
	protected Str opTraceStr() {
		opTrace := ""
		if (operationTrace != null && !operationTrace.isEmpty) {
			opTrace += "\nIoc Operation Trace:\n"
			operationTrace.splitLines.each |op, i| { 
				opTrace += ("  [${(i+1).toStr.justr(2)}] $op\n")
			}
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
	
	new make(Str msg, Obj?[] availableValues, Err? cause := null, Str? opTrace := null) : super(msg, cause, opTrace) {
		this.availableValues = availableValues.map { it?.toStr }.sort
	}
	
	override Str toStr() {
		opTrace := causeStr
		opTrace += opTraceStr
		opTrace += availStr
		opTrace += "Stack Trace:"
		return opTrace				
	}
	
	protected Str availStr() {
		buf := StrBuf()
		buf.add("\n${valueMsg}\n")
		availableValues.each { buf.add("  $it\n")}
		buf.add("\n")
		return buf.toStr
	}
}

** Thrown when an impossible condition occurs. You know when - we've all written comments like:
** 
** '// this should never happen...' 
@NoDoc	// Who cares?
const class WtfErr : Err {
	new make(Str msg, Err? cause := null) : super(msg, cause) {}
}
