
** Use to override definitions of an IoC service.
** 
** pre>
** syntax: fantom
** overrideBuilder := regBuilder.overrideService("acme::Sheep")
** overrideBuilder
**     .withImplType(WolfImpl#)
**     .withCtorVals(["teeth"])
**     .withScope("root")
** <pre
@Js
mixin ServiceOverrideBuilder {
	
	** Overrides the service implementation.
	abstract This withImplType(Type? implType)
	
	** Overrides service aliases with the given ID.
	abstract This withAlias(Str alias)

	** Overrides service aliases with the given list.
	abstract This withAliases(Str[]? aliases)

	** Overrides service alias types with the given type.
	abstract This withAliasType(Type aliasType)

	** Overrides service alias types with the given list.
	abstract This withAliasTypes(Type[]? aliasTypes)

	** Overrides service scopes with the given scope ID.
	abstract This withScope(Str scope)

	** Overrides service scopes with the given scope list.
	abstract This withScopes(Str[]? scopes)
	
	** Overrides the service builder func. 
	abstract This withBuilder(|Scope -> Obj|? serviceBuilder)
	
	** Overrides the service ctor args. 
	abstract This withCtorArgs(Obj?[]? args)

	** Overrides the service field vals. 
	abstract This withFieldVals([Field:Obj?]? fieldVals)

	** Marks this override as *optional*. That is, should the service you're attempting to override 
	** not exist, no errors are thrown and this override is silently ignored.
	** 
	** Useful for overriding 3rd party libraries that may not be part of the current project.
	abstract This optional(Bool optional := true)

	** Sets an override ID so others may override this override.
	** 
	** pre>
	** syntax: fantom
	** // override the sheep service
	** regBuilder.overrideService("acme::Sheep").withOverrideId("wolf").withImplType(WolfImpl#)
	** 
	** // override the wolf override
	** regBuilder.overrideService("wolf").withOverrideId("bear").withImplType(BearImpl#)
	** 
	** // override the bear override
	** regBuilder.overrideService("bear").withOverrideId("frog").withImplType(FrogImpl#)
	** 
	** <pre
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

	override This withAlias(Str alias) {
		ovrDef.aliases = Str[alias]
		return this
	}

	override This withAliases(Str[]? aliases) {
		ovrDef.aliases = aliases
		return this
	}

	override This withAliasType(Type aliasType) {
		ovrDef.aliasTypes = [aliasType]
		return this
	}
	
	override This withAliasTypes(Type[]? aliasTypes) {
		ovrDef.aliasTypes = aliasTypes
		return this
	}
	
	override This withScope(Str serviceScope) {
		withScopes([serviceScope])
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
