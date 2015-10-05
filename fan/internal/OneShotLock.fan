using concurrent::AtomicBool

@Js
internal const class OneShotLock {
	
	private const Str			because
	private const Type			errType
	private const AtomicBool	lockFlag	:= AtomicBool(false)
	
	new make(Str because, Type errType := IocErr#) {
		this.because = because
		this.errType = errType
	}
	
	Bool lock() {
		lockFlag.getAndSet(true)
	}

	Bool locked() {
		lockFlag.val
	}
	
	Void check() {
		if (lockFlag.val)
			throwErr
	}

	Void throwErr() {
		throw errType.make([ErrMsgs.oneShotLockViolation(because)])
	}
	
	override Str toStr() {
		(lockFlag.val ? "" : "(un)") + "locked"
	}
}
