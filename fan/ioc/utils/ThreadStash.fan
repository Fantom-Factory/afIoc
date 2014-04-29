using concurrent::Actor

** A wrapper around [Actor.locals]`concurrent::Actor.locals` that ensures a unique names per 
** instance. This means you don't have to worry about name clashes. 
** 
** Example usage:
** 
** pre>
**   stash1 := ThreadStash("name")
**   stash1["wot"] = "top"
** 
**   stash2 := ThreadStash("name")
**   stash2["wot"] = "banana"
** 
**   echo(stash1["wot"])  // --> top
**   echo(stash2["wot"])  // --> banana
** <pre
** 
** Though typically you would create calculated field wrappers for your variables:
** 
** pre>
** const class Example
**   private const ThreadStash stash := LocalStash(typeof.name)
**   
**   MyService wotever {
**     get { stash["wotever"] }
**     set { stash["wotever"] = it }
**   }
** }
** <pre
**
** Also see `ThreadStashManager` to ensure your thread values get cleaned up, say, at the end of a 
** HTTP web request.
** 
** @since 1.3.0 (a replacement for 'LocalStash')
@NoDoc @Deprecated { msg="Use 'afConcurrent::LocalMap' instead" }
const class ThreadStash {

	** The prefix used to identify all keys used with this stash
	const Str prefix

	private Int? counter {
		get { Actor.locals["${typeof.qname}.counter"] }
		set { Actor.locals["${typeof.qname}.counter"] = it }
	}
	
	** A thread-local count is added to the given prefix to make it truly unique.
	new make(Str prefix) {
		this.prefix = createPrefix(prefix)
	}
	
	** Get the value for the specified name.
	** 
	** 'defFunc' parameter is deprecated... use 'getOrAdd()' instead.
	@Operator
	Obj? get(Str name, |->Obj|? defFunc := null) {
		getOrAdd(name, defFunc)
	}

	** Get the value for the specified name, or if it doesn't exist then automatically add it. 
	** The value function is called to get the value to add, it is only called if the key is not
	** mapped.
	Obj? getOrAdd(Str name, |->Obj|? defFunc := null) {
		val := Actor.locals[key(name)]
		if (val == null) {
			if (defFunc != null) {
				val = defFunc.call
				set(name, val)
			}
		}
		return val
	}

	** Set the value for the specified name. If the name was already mapped, this overwrites the old 
	** value.
	@Operator
	Void set(Str name, Obj? value) {
		Actor.locals[key(name)] = value
	}
	
	** Returns all (fully qualified) keys associated / used with this stash. Note the returns 
	Str[] keys() {
		Actor.locals.keys
			.findAll { it.startsWith(prefix) }
			.sort
	}

	** Returns 'true' if this stash contains the given name
	** 
	** @since 1.3.2
	Bool contains(Str name) {
		keys.contains(key(name))
	}
	
	** Remove the name/value pair from the stash and returns the value that was. If the name was 
	** not mapped then return null.
	Obj? remove(Str name) {
		Actor.locals.remove(key(name))
	}
	
	** Removes all key/value pairs from this stash
	Void clear() {
		keys.each { Actor.locals.remove(it) }
	}

	// ---- Helper Methods ------------------------------------------------------------------------

	private Str createPrefix(Str strPrefix) {
		count 	:= counter ?: 1
		padded	:= count.toStr.padl(4, '0')
		prefix 	:= "${strPrefix}.${padded}."
		counter = count + 1
		return prefix
	}

	private Str key(Str name) {
		return "${prefix}${name}"
	}
}
