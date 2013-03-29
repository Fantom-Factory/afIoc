
internal class OneShotLock {
	
	private Bool lockFlag
	
	Void lock() {
		check	// you can't lock twice!
		lockFlag = true
	}
	
	public Void check() {
		if (lockFlag)
			throw IocErr(IocMessages.oneShotLockViolation)
	}
	
	override Str toStr() {
		(lockFlag ? "" : "(un)") + "locked"
	}
}
