
** Creates and keeps tabs on `ThreadStash` so they may be cleaned up, say, at the end of a web 
** request.
** 
** @since 1.3.0
const mixin ThreadStashManager {

	** creates a stash with the given prefix
	abstract ThreadStash createStash(Str owner)

	** Returns all (fully qualified) keys associated / used with this manager 
	abstract Str[] keys() 
	
	** Removes all values associated / used with this manager
	abstract Void cleanUp()
	
}
