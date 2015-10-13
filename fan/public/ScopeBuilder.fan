
** Use to define an IoC scope.
** 
** pre>
** syntax: fantom
** scopeBuilder := regBuilder.addScope("thread")
** scopeBuilder.withAlias("request")
** <pre
** 
** Or inline:
** 
** pre>
** syntax: fantom
** regBuilder.addScope("thread").withAlias("request")
** <pre
** 
@Js
mixin ScopeBuilder {
	
	** Add an alias. An alias is a different name the Scope may be known by.
	** 
	** pre>
	** syntax: fantom
	** reg := regBuilder.addScope("thread").withAlias("request").build
	** 
	** reg.rootScope.createChildScope("thread") { ... }
	** 
	** reg.rootScope.createChildScope("request") { ... }
	** <pre
	** 
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
