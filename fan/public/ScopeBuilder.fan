
@Js
mixin ScopeBuilder {
	
	abstract This addAlias(Str serviceAlias)

}

@Js
internal class ScopeBuilderImpl : ScopeBuilder {
	internal ScpDef	scopeDef
	
	new make(|This|in) { in(this) }
	
	override This addAlias(Str scopeAlias) {
		if (scopeDef.aliases == null)
			scopeDef.aliases = Str[,]
		scopeDef.aliases.add(scopeAlias)
		return this
	}

}
