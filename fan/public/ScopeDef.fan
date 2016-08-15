
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

	Err[]? callCreateHooks(Scope? parent) {
		errors  := null as Err[]
		configs	:= (Func[]?) createRefs.val
		if (configs != null && configs.isEmpty.not) {
			config	:= ConfigurationImpl(parent, Str:|Scope|#, "afIoc::Scope.onCreate")
			configs.each {
				try {
					it.call(config)
					config.cleanupAfterMethod
				} catch (Err err) {
					if (errors == null)
						errors = Err[,]
					errors.add(err)
				}
			}
			hooks := (Str:Func) config.toMap
			hooks.each {
				try	it.call(parent)
				catch (Err err) {
					if (errors == null)
						errors = Err[,]
					errors.add(err)
				}
			}
		}
		return errors
	}

	Err[]? callDestroyHooks(Scope? parent) {
		errors  := null as Err[]
		configs	:= (Func[]?) destroyRefs.val
		if (configs != null && configs.isEmpty.not) {
			config	:= ConfigurationImpl(parent, Str:|Scope|#, "afIoc::Scope.onDestroy")
			configs.each {
				try {
					it.call(config)
					config.cleanupAfterMethod
				} catch (Err err) {
					if (errors == null)
						errors = Err[,]
					errors.add(err)
				}
			}
			hooks := (Str:Func) config.toMap
			hooks.each {
				try it.call(parent)
				catch (Err err) {
					if (errors == null)
						errors = Err[,]
					errors.add(err)
				}
			}
		}
		return errors
	}
}
