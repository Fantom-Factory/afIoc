
** What's the plan, Stan?
** 
** Sometimes, when an error occurs, the Stack Trace just doesn't give enough contextual 
** information. That's where the 'OpTracker' comes in.   
internal class OpTracker {
	private const static Log 	logger 		:= Utils.getLog(OpTracker#)
	private OpTrackerOp[]		operations	:= [,]
	private Bool				logged		:= false
	private LogLevel			logLevel	:= LogLevel.debug

	new makeWithLoglevel(LogLevel logLevel) {
		this.logLevel = logLevel
	}
	
	new make(Str? lifetimeMsg := null) {
		if (lifetimeMsg != null)
			pushOp(lifetimeMsg)
	}
	
	Void end() {
		if (operations.size != 1)
			throw Err("OpTracker.end() invoked when the operations stack has $operations.size op(s). There should only be ONE... Fool.")
		popOp
	}
	
	Obj? track(Str description, |->Obj?| operation) {
		pushOp(description)
		
		try {
			return operation()
			
		} catch (Err err) {
			if (!logged) {
				opTrace := err is IocErr ? "" : err.typeof.qname + ": " 
				opTrace += (err.msg.isEmpty ? "" : err.msg) + "\n"
				opTrace += "Operations trace:\n"
		        operations.each |op, i| {
		        	opTrace += "  [${(i+1).toStr.justr(2)}] $op.description\n"
		        }
				
				logged = true
				throw OpTrackerErr(opTrace, err)
			}
			throw err

		} finally {
			popOp
			
            // we've finally backed out of the operation stack ... but more maybe added!
            if (operations.isEmpty)
                logged = false	
		}
	}
	
	Void logExpensive(|->Str| msg) {
		if (logEnabled) {
			log(msg())
		}
	}

	Void log(Str description) {
		if (logEnabled) {
			depth 	  := operations.size
			pad 	  := "".justr(depth)		
			loggy("[${depth.toStr.justr(3)}] ${pad}  > $description")
		}
	}
	
	Duration startTime() {
		operations[0].startTime
	}
	
	private Void pushOp(Str description) {
		op := OpTrackerOp {
			it.description 	= description
			it.startTime	= Duration.now
		}
		
		if (logEnabled) {
			depth 	:= operations.size + 1
			pad		:= "".justr(depth)
			loggy("[${depth.toStr.justr(3)}] ${pad}--> $op.description")
		}

		operations.push(op)
	}

	private Void popOp() {
		op := operations.pop
		if (logEnabled) {
			depth 	:= operations.size + 1
			pad		:= "".justr(depth)			
			millis	:= (Duration.now - op.startTime).toMillis.toLocale("#,000")
			loggy("[${depth.toStr.justr(3)}] ${pad}<-- $op.description [${millis}ms]")
		}
	}
	
	private Bool logEnabled() {
		return logger.isEnabled(logLevel)
	}

	private Void loggy(Str msg) {
		rec := LogRec(DateTime.now, logLevel, logger.name, msg)
		logger.log(rec)
	}
}

internal const class OpTrackerOp {
	const Str 		description
	const Duration 	startTime
	
	new make(|This|? f := null) { f?.call(this)	}
}

internal const class OpTrackerErr : IocErr {
	internal new make(Str msg := "", Err? cause := null) : super(msg, cause) {}
}
