
@Js
mixin ServiceBuilder {
	
	abstract This withId(Str? serviceId)

	abstract This withType(Type serviceType)

	abstract This withImplType(Type? serviceImplType)
	
	abstract This addAlias(Str serviceAlias)

	abstract This addAliasType(Type serviceAliasType)

//	abstract This addScope(Str scope)

	abstract This withScope(Str scope)

	abstract This withScopes(Str[]? serviceScopes)

	abstract This withRootScope()
	
	abstract This withBuilder(|Scope -> Obj|? serviceBuilder)
	
	** Passed as args to the service ctor. The args must be immutable.
	abstract This withCtorArgs(Obj?[]? args)

	** Field values to set in the service impl. An alternative to using ctor args. All vals must be immutable.
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

	override This addAlias(Str serviceAlias) {
		if (srvDef.aliases == null)
			srvDef.aliases = Str[,]
		srvDef.aliases.add(serviceAlias)
		return this
	}

	override This addAliasType(Type serviceAliasType) {
		if (srvDef.aliasTypes == null)
			srvDef.aliasTypes = Type[,]
		srvDef.aliasTypes.add(serviceAliasType)
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
	
	override This withBuilder(|Scope -> Obj|? serviceBuilder) {
		srvDef.builder = toImmutableObj(serviceBuilder)
		if (serviceBuilder != null) {
			srvDef.autobuild	= false
			srvDef.implType	= null
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
	
	private Obj? toImmutableObj(Obj? obj) {
		if (obj is Func)
			return Env.cur.runtime == "js" ? obj : obj.toImmutable
		return obj?.toImmutable
	}
}
