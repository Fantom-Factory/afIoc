
** @Inject -
** Creates and keeps tabs on `ThreadStash`s so they may be cleaned up, say, at the end of a web 
** request.
** 
** @since 1.3.0
const mixin ThreadStashManager {

	** creates a stash with the given prefix
	abstract ThreadStash createStash(Str owner)

	** Returns all (fully qualified) keys in the current thread associated / used with this manager 
	abstract Str[] keys() 
	
	** Add a handler to be called on thread clean up
	abstract Void addCleanUpHandler(|->| handler)
	
	** Removes all values in the current thread associated / used with this manager
	abstract Void cleanUpThread()
	
}
