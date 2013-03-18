
internal class OneShotLock {
	
	private Bool lockFlag
	
	Void lock() {
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
