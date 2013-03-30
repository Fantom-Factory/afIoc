
** What's the plan, Stan?
** 
** Sometimes, when an error occurs, the Stack Trace just doesn't give enough contextual 
** information. That's where the 'OpTracker' comes in.   
internal class OpTracker {
	private const static Log 	logger 		:= Utils.getLog(OpTracker#)
	private OpTrackerOp[]		operations	:= [,]
	private Bool				logged		:= false

	new make(Str? lifetimeMsg := null) {
		if (lifetimeMsg != null)
			pushOp(lifetimeMsg)
	}
	
	Void end() {
		if (operations.size != 1)
			throw Err("OpTracker.end() invoked when the operations stack has $operations.size op(s). There should only be ONE... Fool.")
		popOp
	}
	
	Obj? track(Str description, |OpTracker->Obj?| operation) {
		pushOp(description)
		
		try {
			return operation(this)
			
		} catch (Err err) {
			if (!logged) {
		        logger.err(err.msg.isEmpty ? err.typeof.qname : err.msg)
		        logger.err("Operations trace:")
		        operations.each |op, i| {   
		        	logger.err("[${(i+1).toStr.justr(2)}] $op.description")
		        }
				logged = true
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
		if (logger.isDebug) {
			depth 	  := operations.size
			pad 	  := "".justr(depth)		
			logger.debug("[${depth.toStr.justr(3)}] ${pad}  > $description")
		}
	}
	
	private Void pushOp(Str description) {
		op := OpTrackerOp {
			it.description 	= description
			it.startTime	= Duration.now
		}
		
		if (logger.isDebug) {
			depth 	:= operations.size + 1
			pad		:= "".justr(depth)
			logger.debug("[${depth.toStr.justr(3)}] ${pad}--> $op.description")
		}

		operations.push(op)
	}

	private Void popOp() {
		op := operations.pop
		if (logger.isDebug) {
			depth 	:= operations.size + 1
			pad		:= "".justr(depth)			
			millis	:= (Duration.now - op.startTime).toMillis.toLocale("#,000")
			logger.debug("[${depth.toStr.justr(3)}] ${pad}<-- $op.description [${millis}ms]")
		}
	}
}

internal const class OpTrackerOp {
	const Str 		description
	const Duration 	startTime
	
	new make(|This|? f := null) { f?.call(this)	}
}
