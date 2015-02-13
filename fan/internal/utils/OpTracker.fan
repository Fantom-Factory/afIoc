
** What's the plan, Stan?
** 
** Sometimes, when an error occurs, the Stack Trace just doesn't give enough contextual 
** information. That's where the 'OpTracker' comes in.   
internal class OpTracker {
	private const static Log 	logger 		:= Utils.getLog(OpTracker#)
	private OpTrackerOp[]		operations	:= List(OpTrackerOp#, 255)
	private Bool				logged		:= false
	private LogLevel			logLevel	:= LogLevel.debug

//	new makeWithLoglevel(LogLevel logLevel) {
//		this.logLevel = logLevel
//	}
	
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
				logged = true
				opTrace := operations.join("\n") { stripSys(it.description) }
				throw IocErr(err.msg, err, opTrace)
			}
			throw err

		} finally {
			popOp
			
            // we've finally backed out of the operation stack ... but more maybe added!
            if (operations.isEmpty)
                logged = false	
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
		// don't log if we're backing out of an error
		if (logEnabled && !logged) {
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
	
	override Str toStr() {
		"$operations.size operations deep..."
	}
	
	private static Str stripSys(Str str) {
		str.replace("sys::", "")
	}
}

internal const class OpTrackerOp {
	const Str 		description
	const Duration 	startTime
	
	new make(|This|? f := null) { f?.call(this)	}
	
	override Str toStr() {
		description
	}
}

