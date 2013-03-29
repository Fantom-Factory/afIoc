
** What's the plan, Stan?
** 
** Sometimes, when an error occurs, the Stack Trace just doesn't give enough contextual 
** information. That's where the 'OpTracker' comes in.   
internal class OpTracker {
	private const static Log 	logger 		:= Utils.getLog(OpTracker#)
	private Str[] 				operations	:= [,]
	private Bool				logged		:= false

	private Str?				createMsg
	private Duration			createTime	:= Duration.now
	
	new make(Str? lifetimeMsg := null) {
		if (lifetimeMsg != null) {
			logDescIn(lifetimeMsg)
			operations.push(lifetimeMsg)
			createMsg = lifetimeMsg
		}
	}
	
	Void end() {
		if (createMsg == null) throw Err("Stoopid!")
		// TODO: should have a obj to hold this stuff
		logDescOut(createMsg, createTime)
		operations.pop
	}
	
	Obj? track(Str description, |OpTracker->Obj?| operation) {
		startTime := Duration.now
		
		logDescIn(description)
		operations.push(description)
		
		try {
			ret := operation(this)
			logDescOut(description, startTime)
			return ret
			
		} catch (Err err) {
			if (!logged) {
		        logger.err(err.msg.isEmpty ? err.typeof.qname : err.msg)
		        logger.err("Operations trace:")
		        operations.each |op, i| {   
		        	logger.err("[${(i+1).toStr.justr(2)}] $op")
		        }
				logged = true
			}
			throw err

		} finally {
			operations.pop
			
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
	
	private Void logDescIn(Str description) {
		if (logger.isDebug) {
			depth 	:= operations.size + 1
			pad		:= "".justr(depth)
			logger.debug("[${depth.toStr.justr(3)}] ${pad}--> $description")
		}
	}

	private Void logDescOut(Str description, Duration startTime) {
		if (logger.isDebug) {
			depth 	:= operations.size
			pad		:= "".justr(depth)			
			millis	:= (Duration.now - startTime).toMillis.toLocale("#,000")
			logger.debug("[${depth.toStr.justr(3)}] ${pad}<-- $description [${millis}ms]")
		}
	}
	
}
