
@Js
mixin ServiceOverrideBuilder {
	
	abstract This withImplType(Type? serviceImplType)
	
	abstract This addAlias(Str serviceAlias)

	abstract This addAliasType(Type serviceAliasType)

	abstract This withScopes(Str[]? serviceScopes)
	
	abstract This withBuilder(|Scope -> Obj|? serviceBuilder)
	
	** Passed as args to the service ctor. The args must be immutable.
	abstract This withCtorArgs(Obj?[]? args)

	** Field values to set in the service impl. An alternative to using ctor args. All vals must be immutable.
	abstract This withFieldVals([Field:Obj?]? fieldVals)

	abstract This optional(Bool optional := true)

	abstract This withOverrideId(Str overrideId)
}

@Js
internal class ServiceOverrideBuilderImpl : ServiceOverrideBuilder {
	
	internal OvrDef	ovrDef
	
	internal new make(Type moduleId) {
		this.ovrDef	= OvrDef {
			it.moduleId	= moduleId
		}
	}

	override This withImplType(Type? serviceImplType) {
		if (serviceImplType != null && serviceImplType.isMixin) 
			throw ArgErr(ErrMsgs.autobuilder_bindImplNotClass(serviceImplType))
		ovrDef.implType = serviceImplType

		if (serviceImplType != null) {
			ovrDef.autobuild	= true
			ovrDef.builder		= null
			if (ovrDef.overrideId == null)
				ovrDef.overrideId = serviceImplType.qname
		} else
			ovrDef.autobuild	= false

		return this
	}

	override This addAlias(Str serviceAlias) {
		if (ovrDef.aliases == null)
			ovrDef.aliases = Str[,]
		ovrDef.aliases.add(serviceAlias)
		return this
	}

	override This addAliasType(Type serviceAliasType) {
		if (ovrDef.aliasTypes == null)
			ovrDef.aliasTypes = Type[,]
		ovrDef.aliasTypes.add(serviceAliasType)
		return this
	}
	
	override This withScopes(Str[]? serviceScopes) {
		ovrDef.scopes = toImmutableObj(serviceScopes)
		return this
	}
	
	override This withBuilder(|Scope -> Obj|? serviceBuilder) {
		ovrDef.builder = toImmutableObj(serviceBuilder)
		if (serviceBuilder != null) {
			ovrDef.autobuild	= false
			ovrDef.implType	= null
		} else
			ovrDef.autobuild	= true
		return this
	}
	
	** Passed as args to the service ctor. The args must be immutable.
	override This withCtorArgs(Obj?[]? args) {
		ovrDef.ctorArgs = toImmutableObj(args)
		if (args != null)	// if null, we may not be autobuilding
			ovrDef.autobuild = true
		return this
	}

	** Field values to set in the service impl. An alternative to using ctor args. All vals must be immutable.
	override This withFieldVals([Field:Obj?]? fieldVals) {
		ovrDef.fieldVals = toImmutableObj(fieldVals)
		if (fieldVals != null)	// if null, we may not be autobuilding
			ovrDef.autobuild = true
		return this
	}

	override This optional(Bool optional := true) {
		ovrDef.optional = optional
		return this
	}

	override This withOverrideId(Str overrideId) {
		ovrDef.overrideId = overrideId
		return this
	}
	
	private Obj? toImmutableObj(Obj? obj) {
		if (obj is Func)
			return Env.cur.runtime == "js" ? obj : obj.toImmutable
		return obj?.toImmutable
	}
}
