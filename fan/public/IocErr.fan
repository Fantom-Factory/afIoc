using afBeanUtils::NotFoundErr

** As thrown by IoC.
@Js
const class IocErr : Err {
	
	** A trace of IoC operations that led to the Err. 
	** A succinct and more informative stack trace if you will.
	const Str? operationTrace
	
	@NoDoc
	new make(Str msg := "", Err? cause := null) : super(msg, cause) {
		// TODO: find a reference to the containing Registry
		// until we do, all opTraces will refer to the same Reg instance
		// but, to be fair, it's unlikely there'll ever be more than one!
		this.operationTrace = ServiceInjectStack(1).operations.join("\n")
	}
	
	@NoDoc
	override Str toStr() {
		opTraceStr := opTraceStr
		opTrace := causeStr
		opTrace += opTraceStr
		opTrace += opTraceStr.isEmpty ? "" : "Stack Trace:"
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
		if (operationTrace?.trimToNull == null) return ""
		opTrace := "\nIoC Operation Trace:\n"
		lines	:= operationTrace?.splitLines ?: Str#.emptyList
		lines.each |op, i| { 
			opTrace += ("  [${(lines.size - i).toStr.justr(2)}] $op\n")
		}
		return opTrace
	}
}

** Thrown when Registry methods are invoked after it has been shutdown. 
** This has a dedicated Err class so it may be catered for explicitly.
@Js @NoDoc	// Advanced use only
const class RegistryShutdownErr : IocErr {
	new make(Str msg, Err? cause := null) : super(msg, cause) {}
}

** Thrown when Scope methods are invoked after it has been destroyed. 
** This has a dedicated Err class so it may be catered for explicitly.
@Js @NoDoc	// Advanced use only
const class ScopeDestroyedErr : IocErr {
	new make(Str msg, Err? cause := null) : super(msg, cause) {}
}

@Js @NoDoc
const class ServiceNotFoundErr : IocErr, NotFoundErr {
	override const Str[] availableValues
	override const Str	 valueMsg := "Available Service IDs:"

	new make(Str msg, Obj?[] availableValues, Err? cause := null) : super(msg, cause) {
		this.availableValues = availableValues.map { it?.toStr }.sort
	}
	
	protected Str availStr() {
		buf := StrBuf()
		buf.add("\n${valueMsg}\n")
		availableValues.each { buf.add("  $it\n")}
		buf.add("\n")
		return buf.toStr
	}

	override Str toStr() {
		opTrace := causeStr
		opTrace += opTraceStr
		opTrace += availStr
		opTrace += "Stack Trace:"
		return opTrace				
	}
}

	// internal so it doesn't interfere with the one in afBeanUtils
@Js	// 'cos we can't subclass ArgErr in JS - see http://fantom.org/forum/topic/2468
internal const class ArgNotFoundErr : IocErr, NotFoundErr {
	override const Str?[] availableValues
	
	new make(Str msg, Obj?[] availableValues, Err? cause := null) : super.make(msg, cause) {
		this.availableValues = availableValues.map { it?.toStr }.sort
	}
	
	Str valuesStr() {
		buf := StrBuf()
		buf.add("\n${typeof.qname}: ${msg}\n")
		buf.add("\n${valueMsg}\n")
		availableValues.each { buf.add("  $it\n")}
		return buf.toStr
	}
	
	override Str toStr() {
		opTrace := causeStr
		opTrace += opTraceStr
		opTrace += valuesStr
		opTrace += "Stack Trace:"
		return opTrace				
	}
}
