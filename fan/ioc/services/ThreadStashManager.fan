using concurrent

@NoDoc @Deprecated { msg="Use 'ThreadLocals' instead" }
const mixin ThreadStashManager {

	abstract ThreadStash createStash(Str owner)

	abstract Str[] keys() 
	
	abstract Void addCleanUpHandler(|->| handler)
	
	abstract Void cleanUpThread()
}
