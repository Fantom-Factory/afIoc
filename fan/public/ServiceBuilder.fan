
** Use to define an IoC service.
** 
** pre>
** syntax: fantom
** serviceBuilder := regBuilder.addService()
** serviceBuilder
**     .withId("acme::penguins")
**     .withType(Penguins#)
**     .withImplType(PenguinsImpl#)
**     .withScope("root")
** <pre
** 
** The above could be inlined and, taking advantage of defaults, could be shortened to just:
** 
** pre>
** syntax: fantom
** regBuilder.addService(Penguins#).withRootScope
** <pre
@Js
mixin ServiceBuilder {

	** Sets the unique service ID.
	** If not set explicitly it is taken to be the qualified Type name.
	** 
	** pre>
	** syntax: fantom
	** regBuilder.addService.withId("thread")
	** <pre
	abstract This withId(Str? id)

	** Sets the type of the service. May also be set via 'addService()'. 
	** 
	** pre>
	** syntax: fantom
	** regBuilder.addService(Penguin#)
	** 
	** regBuilder.addService.withType(Penguin#)
	** <pre
	** 
	** If the service type is a mixin then either an implementation type or a builder must be subsequently set.
	** 
	** pre>
	** syntax: fantom
	** regBuilder.addService(IPenguin#).withImplType(PenguinImpl#)
	** <pre
	** 
	abstract This withType(Type type)

	** Sets the implementation of the service. Used when the service is autobuilt. May also be set via 'addService()'.
	** 
	** pre>
	** syntax: fantom
	** regBuilder.addService(IPenguin#, PenguinImpl#)
	** 
	** regBuilder.addService(Penguin#).withImplType(PenguinImpl#)
	** <pre
	** 
	** 'ImplType' is used, along with 'ctorArgs' and 'fieldVals' to autobuild an instance of the service.
	abstract This withImplType(Type? implType)
	
	** Creates an alias ID that this service is also known as.
	** 
	** pre>
	** syntax: fantom
	** reg := regBuilder { 
	**     addService(Wolf#).withAlias("acme::Sheep") 
	** }.build
	** 
	** reg.rootScope.serviceById("acme::Wolf")
	** 
	** reg.rootScope.serviceById("acme::Sheep")  // --> same service as 'acme::wolf'
	** <pre
	abstract This withAlias(Str alias)

	** Creates multiple aliases that this service is also known as.
	abstract This withAliases(Str[]? aliases)

	** Adds an alias Type that this service is also known as.
	** 
	** pre>
	** syntax: fantom
	** reg := regBuilder { 
	**     addService(Wolf#).withAliasType(Sheep#) 
	** }.build
	** 
	** reg.rootScope.serviceByType(Wolf#)
	** 
	** reg.rootScope.serviceByType(Sheep#)  // --> same service as Wolf
	** <pre
	abstract This withAliasType(Type aliasType)

	** Sets many Types that this service is also known as.
	abstract This withAliasTypes(Type[]? aliasTypes)

	** Sets the scope that the service can be created in.
	** 
	** pre>
	** syntax: fantom
	** regBuilder.addService(Wolf#).withScope("thread")
	** <pre
	abstract This withScope(Str scope)

	** Sets multiple scopes that the service can be created in.
	** 
	** pre>
	** syntax: fantom
	** regBuilder.addService(Wolf#).withScopes(["root", "thread"])
	** <pre
	abstract This withScopes(Str[]? scopes)

	** Convenience for 'withScope("root")'. 
	** 
	** pre>
	** syntax: fantom
	** regBuilder.addService(Wolf#).withRootScope
	** <pre
	abstract This withRootScope()
	
	** Sets a func that creates instances of the services. 
	** 
	** pre>
	** syntax: fantom
	** regBuilder.addService(Wolf#).withBuilder |Scope scope -> Obj?| {
	**     return Penguin()
	** }
	** <pre
	** 
	** 'Scope' is the current scope the service is being built in.
	abstract This withBuilder(|Scope -> Obj?|? serviceBuilder)
	
	** Set constructor arguments to be used when the service is autobuilt. 
	** Note the args must be immutable.
	** 
	** pre>
	** syntax: fantom
	** regBuilder.addService(Penguin#).withCtorArgs([arg1, arg2])
	** <pre
	abstract This withCtorArgs(Obj?[]? args)

	** Set field values to used when the service is autobuilt. 
	** An alternative to using ctor args. 
	** Note all vals must be immutable.
	** 
	** pre>
	** syntax: fantom
	** regBuilder.addService(Penguin#).withFieldVals([Penguin#arg1 : "val1", Penguin#arg2 : "val2"])
	** <pre
	abstract This withFieldVals([Field:Obj?]? fieldVals)
}

@Js
internal class ServiceBuilderImpl : ServiceBuilder {
	internal SrvDef	srvDef
	
	internal new make(Type moduleId) {
		this.srvDef	= SrvDef {
			it.moduleId	= moduleId
		}
	}

	override This withId(Str? serviceId) {
		srvDef.id = serviceId
		return this
	}

	override This withType(Type serviceType) {
		srvDef.type = serviceType.toNonNullable
		if (srvDef.id == null)
			srvDef.id = serviceType.qname
		if (srvDef.builder == null)
			srvDef.autobuild = true
		return this
	}

	override This withImplType(Type? serviceImplType) {
		if (serviceImplType != null && serviceImplType.isMixin) 
			throw ArgErr(ErrMsgs.autobuilder_bindImplNotClass(serviceImplType))
		srvDef.implType = serviceImplType?.toNonNullable

		if (serviceImplType != null) {
			srvDef.autobuild	= true
			srvDef.builder		= null
		} else
			srvDef.autobuild	= false

		return this
	}

	override This withAlias(Str alias) {
		srvDef.aliases = [alias]
		return this
	}

	override This withAliases(Str[]? aliases) {
		srvDef.aliases = aliases
		return this
	}

	override This withAliasType(Type aliasType) {
		srvDef.aliasTypes = [aliasType]
		return this
	}

	override This withAliasTypes(Type[]? aliasTypes) {
		srvDef.aliasTypes = aliasTypes
		return this
	}

	override This withScope(Str scope) {
		withScopes([scope])
	}

	override This withScopes(Str[]? serviceScopes) {
		if (serviceScopes != null && srvDef.moduleId != IocModule# && serviceScopes.any { it.equalsIgnoreCase("builtIn") })
			throw IocErr(ErrMsgs.serviceBuilder_scopeReserved(srvDef.id ?: "", "builtIn"))

		srvDef.declaredScopes = toImmutableObj(serviceScopes)
		return this
	}

	override This withRootScope() {
		withScopes(["root"])
	}
	
//	override This addScope(Str scope) {
//		if (srvDef.moduleId != IocModule#.qname && scope.equalsIgnoreCase("builtIn"))
//			throw IocErr(ErrMsgs.serviceBuilder_scopeReserved(srvDef.id ?: "", "builtIn"))
//
//		srvDef.declaredScopes =  toImmutableObj((srvDef.declaredScopes ?: Str[,]).rw.add(scope))
//		return this
//	}
	
	override This withBuilder(|Scope -> Obj?|? serviceBuilder) {
		srvDef.builder = toImmutableObj(serviceBuilder)
		if (serviceBuilder != null) {
			srvDef.autobuild	= false
			srvDef.implType		= null
		} else
			srvDef.autobuild	= true
		return this
	}
	
	** Passed as args to the service ctor. The args must be immutable.
	override This withCtorArgs(Obj?[]? args) {
		srvDef.ctorArgs = toImmutableObj(args)
		if (args != null)	// if null, we may not be autobuilding
			srvDef.autobuild = true
		return this
	}

	** Field values to set in the service impl. An alternative to using ctor args. All vals must be immutable.
	override This withFieldVals([Field:Obj?]? fieldVals) {
		srvDef.fieldVals = toImmutableObj(fieldVals)
		if (fieldVals != null)	// if null, we may not be autobuilding
			srvDef.autobuild = true
		return this
	}
	
	private static Obj? toImmutableObj(Obj? obj) {
		if (obj is Func)
			return Env.cur.runtime == "js" ? obj : obj.toImmutable
		return obj?.toImmutable
	}
}
