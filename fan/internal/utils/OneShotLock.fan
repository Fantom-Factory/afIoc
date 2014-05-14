using concurrent::AtomicBool

internal const class OneShotLock {
	
	private const Str 			because
	private const AtomicBool	lockFlag	:= AtomicBool(false)
	
	new make(Str because) {
		this.because = because
	}
	
	Void lock() {
		check	// you can't lock twice!
		lockFlag.val = true
	}

	Bool locked() {
		lockFlag.val
	}
	
	Void check() {
		if (lockFlag.val)
			throw IocErr(IocMessages.oneShotLockViolation(because))
	}
	
	override Str toStr() {
		(lockFlag.val ? "" : "(un)") + "locked"
	}
}
