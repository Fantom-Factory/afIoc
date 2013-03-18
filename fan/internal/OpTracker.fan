
** What's the plan, Stan?
** 
** Sometimes, when an error occurs, the Stack Trace just doesn't give enough contextual 
** information. That's where 'OperationTracker' comes in.   
class OpTracker {
	private const static Log 	logger 		:= Utils.getLog(OpTracker#)
	private Str[] 				operations	:= [,]
	private Bool				logged		:= false
	
	Obj? track(Str description, |OpTracker->Obj?| operation) {
		startTime := Duration.now
		depth 	  := operations.size + 1
		pad 	  := "".justr(depth)
		
		if (logger.isDebug) {
			logger.debug("[${depth.toStr.justr(3)}] ${pad}--> $description")
		}
		
		operations.push(description)
		
		try {
			ret := operation(this)

			if (logger.isDebug) {
				millis := (Duration.now - startTime).toMillis.toLocale("#,000")
				logger.debug("[${depth.toStr.justr(3)}] ${pad}<-- $description [${millis}ms]")
			}

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
}
