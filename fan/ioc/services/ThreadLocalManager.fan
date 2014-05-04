using concurrent
using afConcurrent

** (Service) -
** Use to create 'LocalRef' instances whose contents can be *cleaned* up. Erm, I mean deleted! 
**  
** This is particularly important in the context of web applications where resources need to be 
** *cleaned* up at the end of a web request / thread. 
** 
** 'LocalRef' instances may also be injected directed into your classes:
** 
** pre>
** const class Example {
**   @Inject const LocalMap localMap
** 
**   new make(|This|in) { in(this) }
** }
** <pre
** 
** Then when 'cleanUpThread()' is called, all thread local data created by this manager will be
** deleted from 'Actor.locals' 
** 
** @since 1.6.0
const mixin ThreadLocalManager {

	** Creates a `LocalRef` with the given name.
	abstract LocalRef createRef(Str name, Obj? def := null)

	** Creates a `LocalList` with the given name.
	abstract LocalList createList(Str name)

	** Creates a `LocalMap` with the given name.
	abstract LocalMap createMap(Str name)

	** Returns all (fully qualified) keys in the current thread associated / used with this manager. 
	abstract Str[] keys() 
	
	** Add a handler to be called on thread clean up. Handlers need to be added for each thread.
	abstract Void addCleanUpHandler(|->| handler)
	
	** Removes all values in the current thread associated / used with this manager.
	abstract Void cleanUpThread()
}


internal const class ThreadLocalManagerImpl : ThreadLocalManager {
	
	static	
	private const AtomicInt	counter	:= AtomicInt(0)
	private const LocalList	cleanUpHandlers
	
	const Str prefix
	
	new make() {
		this.prefix = createPrefix
		this.cleanUpHandlers = createList("ThreadLocalManager.cleanupHandlers")
	}

	override LocalRef createRef(Str name, Obj? def := null) {
		LocalRef("${prefix}.\${id}.${name}", def)
	}

	override LocalList createList(Str name) {
		LocalList("${prefix}.\${id}.${name}")
	}

	override LocalMap createMap(Str name) {
		LocalMap("${prefix}.\${id}.${name}")
	}

	override Str[] keys() {
		Actor.locals.keys
			.findAll { it.startsWith(prefix) }
			.sort
	}
	
	override Void addCleanUpHandler(|->| handler) {
		cleanUpHandlers.add(handler)
	}
	
	override Void cleanUpThread() {
		cleanUpHandlers.each | |->| handler| { handler.call }
		keys.each { Actor.locals.remove(it) }
	}

	// ---- Helper Methods ------------------------------------------------------------------------
	
	private Str createPrefix() {
		count 	:= counter.incrementAndGet
		padded	:= count.toStr.padl(2, '0')
		prefix 	:= "TLM-${padded}"
		return prefix
	}
}
