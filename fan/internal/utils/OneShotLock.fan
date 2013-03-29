
internal class OneShotLock {
	
	private Str 	because
	private Bool	lockFlag
	
	new make(Str because) {
		this.because = because
	}
	
	Void lock() {
		check	// you can't lock twice!
		lockFlag = true
	}
	
	public Void check() {
		if (lockFlag)
			throw IocErr(IocMessages.oneShotLockViolation(because))
	}
	
	override Str toStr() {
		(lockFlag ? "" : "(un)") + "locked"
	}
}
