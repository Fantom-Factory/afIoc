using concurrent::AtomicBool

internal const class OneShotLock {
	
	private const |->|			errFunc
	private const AtomicBool	lockFlag	:= AtomicBool(false)
	
	new make(Str because) {
		this.errFunc = |->| { throw IocErr(IocMessages.oneShotLockViolation(because)) }
	}

	new makeFromFunc(|->| errFunc) {
		this.errFunc = errFunc
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
			errFunc.call
	}
	
	override Str toStr() {
		(lockFlag.val ? "" : "(un)") + "locked"
	}
}
