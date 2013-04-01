using concurrent

** Little methods to help ease your IoC development.
const class IocHelper {

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
	**     Env.cur.err.printLine("$key = $value")
	**   }
	** 
	static Str:Obj? locals() {
		Str:Obj? map := [:] { ordered = true }
		Actor.locals.keys.sort.each { map[it] = Actor.locals[it] }
		return map
	}	
}
