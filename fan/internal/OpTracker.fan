
** What's the plan, Stan?
** 
** Sometimes, when an error occurs, the Stack Trace just doesn't give enough contextual 
** information. That's where 'OperationTracker' comes in.   
class OpTracker {
	private const static Log 	log 		:= Utils.getLog(OpTracker#)
	private Str[] 				operations	:= [,]
	private Bool				logged		:= false
	
	Obj? track(Str description, |->Obj?| operation) {
		
		startTime := Duration.now
		depth 	  := operations.size + 1
		
		if (log.isDebug) {
			log.debug("[${depth.toStr.justr(3)}] --> $description")
		}
		
		operations.push(description)
		
		try {
			ret := operation()

			if (log.isDebug) {
				millis := (Duration.now - startTime).toMillis.toLocale("#,000")
				log.debug("[${depth.toStr.justr(3)}] <-- $description [${millis}ms]")
			}
			
			return ret
			
		} catch (Err err) {
			if (!logged) {
		        log.err(err.msg.isEmpty ? err.typeof.qname : err.msg)
		        log.err("Operations trace:")
		        operations.each |op, i| {   
		        	log.err("[${i.toStr.justr(2)}] $op")
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
}
