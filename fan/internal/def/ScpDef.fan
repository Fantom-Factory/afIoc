
@Js
internal class ScpDef {
	Type 	moduleId
	Str 	id
	Str[]?	aliases
	Bool	threaded
	Func[]?	createContribs
	Func[]?	destroyContribs
	
	new make(|This|in) {
		in(this)
		if (moduleId != IocModule# && (id.equalsIgnoreCase("builtIn") || id.equalsIgnoreCase("root")))
			throw IocErr(ErrMsgs.scopeBuilder_scopeReserved(id))
	}
	
	Bool matchesGlob(Regex glob) {
		glob.matches(id) || (aliases?.any { glob.matches(it) } ?: false)
	}
	
	ScopeDefImpl toScopeDef() {
		ScopeDefImpl {
			it.id 			= this.id
			it.threaded 	= this.threaded
			it.aliases		= this.aliases ?: Str#.emptyList
			it.scopeIds		= Str[this.id].addAll(it.aliases)
			it.createRefs	= Unsafe(createContribs)
			it.destroyRefs	= Unsafe(destroyContribs)
		}
	}
}
