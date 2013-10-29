using concurrent

internal const class ThreadStashManagerImpl : ThreadStashManager {
	
	private const Str prefix
	
	private Int? counter {
		get { Actor.locals["${ThreadStashManager#.name}.counter"] }
		set { Actor.locals["${ThreadStashManager#.name}.counter"] = it }
	}

	private |->|[] cleanupHandlers {
		get { Actor.locals.getOrAdd("${prefix}.cleanupHandlers") { |->|[,] } }
		set { }
	}

	new make(Str prefix := "ThreadStash") {
		this.prefix = createPrefix(prefix)
	}

	override ThreadStash createStash(Str owner) {
		ThreadStash(prefix + "." + owner)
	}

	override Str[] keys() {
		Actor.locals.keys
			.findAll { it.startsWith(prefix) }
			.sort
	}
	
	override Void addCleanUpHandler(|->| handler) {
		cleanupHandlers.add(handler)
	}
	
	override Void cleanUpThread() {
		cleanupHandlers.each |handler| { handler.call }
		keys.each { Actor.locals.remove(it) }
	}

	// ---- Helper Methods ------------------------------------------------------------------------
	
	private Str createPrefix(Str name) {
		count 	:= counter ?: 1
		padded	:= count.toStr.padl(2, '0')
		prefix 	:= "${name}.${padded}"
		counter = count + 1
		return prefix
	}
}
