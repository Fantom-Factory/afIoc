using concurrent

** Little methods to help ease your IoC development.
const class IocHelper {

	private static const AtomicBool logServiceCreationValue	:= AtomicBool(false)
	
	internal static Void doLogServiceCreation(Type log, Str msg) {
		if (logServiceCreationValue.val)
			Utils.getLog(log).info(msg)
	}

	** Set to 'true' to have Ioc log to INFO when services are created, autobuilt and injected. For
	** extensive debug info, use [debugOperation()]`#debugOperation`.
	** 
	** Defaults to 'false' as Ioc ideally should run quietly in the background and not interfere
	** with the running of your app.
	static Void logServiceCreation(Bool value) {
		logServiceCreationValue.val = value
	}
	
	** Runs the given function with extensive IoC logging turned on. Example usage:
	** 
	**   IocHelper.debugOperation |->| {
	**     registry.dependencyByType(MyService#)
	**   } 
	** 
	static Obj? debugOperation(|->Obj?| operation) {
		Utils.setLoglevel(LogLevel.debug)
		try {
			return operation()
		} finally {
			Utils.setLoglevel(LogLevel.info)
		}
	}
	
	** A read only copy of the 'Actor.locals' map with the keys sorted. Handy for debugging. 
	** Example:
	** 
	**   IocHelper.locals.each |value, key| {
	**     echo("$key = $value")
	**   }
	** 
	static Str:Obj? locals() {
		Str:Obj? map := [:] { ordered = true }
		Actor.locals.keys.sort.each { map[it] = Actor.locals[it] }
		return map
	}
}
