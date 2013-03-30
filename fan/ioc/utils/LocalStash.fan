using concurrent

** A wrapper around [Actor.locals]`concurrent::Actor.locals` ensuring a unique namespace.
const class LocalStash {
	private const Str prefix

	new make(Type type) {
		this.prefix = type.qname
	}

	@Operator
	Obj? get(Str name, |->Obj|? defFunc := null) {
		val := Actor.locals[key(name)]
		if (val == null) {
			if (defFunc != null) {
				val = defFunc.call
				set(name, val)
			}
		}
		return val
	}

	@Operator
	Void set(Str name, Obj? value) {
		Actor.locals[key(name)] = value
	}

	private Str key(Str name) {
		return "${prefix}.${name}"
	}
}