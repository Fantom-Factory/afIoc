
internal class OneShotLock {
	
	private Bool lockFlag
	
	Void lock() {
		lockFlag = true
	}
	
	public Void check() {
		// TODO: Put in UtilMessages.properties / messages
		if (lockFlag)
			throw IocErr("Method %s may no longer be invoked.")
	}
	
	override Str toStr() {
		(lockFlag ? "" : "(un)") + "locked"
	}
}
