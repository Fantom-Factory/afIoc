using concurrent

internal const class ThreadStashManagerImpl : ThreadStashManager {
	
	private const Str prefix
	
	private Int? counter {
		get { Actor.locals["${typeof.qname}.counter"] }
		set { Actor.locals["${typeof.qname}.counter"] = it }
	}

	new make() {
		this.prefix = createPrefix(typeof)
	}

	override ThreadStash createStash(Str owner) {
		ThreadStash(prefix + "." + owner)
	}

	override Str[] keys() {
		Actor.locals.keys
			.findAll { it.startsWith(prefix) }
			.sort
	}
	
	override Void cleanUp() {
		keys.each { Actor.locals.remove(it) }
	}

	// ---- Helper Methods ------------------------------------------------------------------------
	
	private Str createPrefix(Type type) {
		count 	:= counter ?: 1
		padded	:= count.toStr.padl(4, '0')
		prefix 	:= "${type.name}.${padded}."
		counter = count + 1
		return prefix
	}
}
