
** Definition of a Scope. 
** 'ScopeDefs' are returned from [Registry.scopeDefs()]`Registry.scopeDefs`.
@Js
const mixin ScopeDef {
	
	** The Scope's unique ID.
	abstract Str 	id()
	
	** Any aliases (IDs) given to the Scope.
	abstract Str[]	aliases()
	
	** Returns 'true' if this scope is threaded.
	abstract Bool	threaded()
}

@Js
internal const class ScopeDefImpl : ScopeDef {
	override const Str 		id
	override const Str[]	aliases
	override const Bool		threaded
			 const Str[]	scopeIds
			 const Unsafe	createRefs
			 const Unsafe	destroyRefs

	new make(|This|in) {
		in(this)
	}
	
	Bool matchesId(Str scopeId) {
		id.equalsIgnoreCase(scopeId) || aliases.any { it.equalsIgnoreCase(scopeId) }
	}

	Void callCreateHooks(Scope? parent) {
		configs	:= (Func[]?) createRefs.val
		if (configs != null && configs.isEmpty.not) {
			config	:= ConfigurationImpl(parent, Str:|Scope|#, "afIoc::Scope.onCreate")
			configs.each {
				it.call(config)
				config.cleanupAfterMethod
			}
			hooks := (Str:Func) config.toMap
			hooks.each { it.call(parent) }
		}		
	}

	Void callDestroyHooks(Scope? parent) {
		configs	:= (Func[]?) destroyRefs.val
		if (configs != null && configs.isEmpty.not) {
			config	:= ConfigurationImpl(parent, Str:|Scope|#, "afIoc::Scope.onDestroy")
			configs.each {
				it.call(config)
				config.cleanupAfterMethod
			}
			hooks := (Str:Func) config.toMap
			hooks.each { it.call(parent) }
		}		
	}
}
