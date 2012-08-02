
internal class OperationTracker {
    private Log 	logger
    private Str[] 	operations 	:= [,]
    private Bool 	logged		:= false

    new make(Log logger) {
        this.logger = logger
    }

    Obj? invoke(Str description, Func operation) {
        startNanos := Duration.now

        operations.push(description)

        try {
            return operation.call

        } catch (Err ex) {
            logAndRethrow(ex)
            throw ex;

        } finally {
            operations.pop

            // We've finally backed out of the operation stack ... but there may be more to come!
            if (operations.isEmpty)
                logged = false
        }
    }

    private Void logAndRethrow(Err ex) {
        if (!logged) {
            trace := log(ex);
            logged = true
            throw OperationErr(ex, trace)
        }
    }

    private Str[] log(Err ex) {
        logger.err(ex.msg)
        logger.err("Operations trace:")

		operations.each |str, i| {
            logger.err("[${i.toStr.padl(2,' ')}] ${str}")
		}
        return operations.dup
    }

    Bool isEmpty() {
        operations.isEmpty
    }	
	
}

internal const class OperationErr : IocErr {
	const Str[] opTrace
	
	new make(Err cause, Str[] trace) : super(cause.msg, cause) {
		this.opTrace = trace.toImmutable
	}	
}
