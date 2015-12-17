
@Js
internal class SrvDef {
	Type 			moduleId	// see ErrMsgs.registry_serviceAlreadyDefined()
	Str? 			id
	Type?			type  
	|Scope->Obj|?	builder
	Str[]?			aliases
	Type[]?			aliasTypes
	ContribDef[]?	contribDefs
	Func[]?			buildContribs
	Str[]?			declaredScopes
	Str[]			matchedScopes	:= Str[,]

	Bool			autobuild
	Type?			implType
	Obj?[]?			ctorArgs
	[Field:Obj?]?	fieldVals

	Obj?			builtInInstance
	
	new make(|This|in) { in(this) }
	
	Void addContribDef(ContribDef def) {
		if (contribDefs == null)
			contribDefs = ContribDef[,]
		contribDefs.add(def)
	}
	
	Bool matchesId(Str serviceId) {
		id.equalsIgnoreCase(serviceId) || (aliases?.any { it.equalsIgnoreCase(serviceId) } ?: false)
	}

	Bool matchesType(Type serviceType) {
		type == serviceType || (aliasTypes?.any { it == serviceType } ?: false)
	}
	
	Bool matchesGlob(Regex glob) {
		glob.matches(id) || (aliases?.any { glob.matches(it) } ?: false)
	}
	
	Bool matchesScope(ScopeDefImpl scopeDef) {
		scopeIds := (Str[]) (declaredScopes ?: Str#.emptyList)
		// builtIn scope must have an *exact* match
		return scopeDef.id == "builtIn"
			? "builtIn" == scopeIds.first
			: (scopeIds.isEmpty
				// const classes are only matched to root and 
				// non-const classes are only matched to threaded scopes
				? (type.isConst.xor(scopeDef.threaded)) 
				: scopeIds.any |id| { scopeDef.scopeIds.any { id.equalsIgnoreCase(it) && (scopeDef.threaded || type.isConst) } }
			)
	}

	Type[] serviceTypes() {
		types := Type[,]
		if (type != null)
			types.add(type)
		if (aliasTypes != null)
			types.addAll(aliasTypes)
		return types
	}
	
	Void applyOverride(OvrDef serviceOverride) {

		if (id == null)		throw IocErr(ErrMsgs.serviceBuilder_noId)
		if (type == null)	throw IocErr(ErrMsgs.serviceBuilder_noType(id))
		serviceOverride.gotService?.call(this.id, this.type)
		
		if (serviceOverride.aliases != null)
			this.aliases = serviceOverride.aliases
		
		if (serviceOverride.aliasTypes != null)
			this.aliasTypes = serviceOverride.aliasTypes
		
		if (serviceOverride.scopes != null)
			this.declaredScopes = serviceOverride.scopes
		
		if (serviceOverride.builder != null) {
			this.builder = serviceOverride.builder
			this.autobuild = false 
		}

		if (serviceOverride.implType != null) {
			this.implType = serviceOverride.implType
			this.autobuild = true			
		}

		if (serviceOverride.ctorArgs != null) {
			this.ctorArgs = serviceOverride.ctorArgs
			this.autobuild = true
		}

		if (serviceOverride.fieldVals != null) {
			this.fieldVals = serviceOverride.fieldVals
			this.autobuild = true			
		}
	}

	Void createBuilder() {
		// defer builder func until such a time when we have data
		if (id == null || (type == null && implType == null))
			return
		
		serviceId	:= id
		serviceType	:= type
		serviceImpl	:= implType
		ctorArgs	:= ctorArgs?.ro?.toImmutable	// builders should have already ensured immutability
		fieldVals	:= fieldVals?.ro?.toImmutable	// builders should have already ensured immutability
		builder 	= |Scope currentScope->Obj| {
			scope 		:= (ScopeImpl) currentScope
			buildType	:= scope.registry.autoBuilder.findImplType(serviceType, serviceImpl)
			return scope.registry.autoBuilder.autobuild(currentScope, buildType, ctorArgs, fieldVals, serviceId)
		}
	}

	ServiceDefImpl toServiceDef() {
		if (autobuild)			createBuilder
		if (id == null)			throw IocErr(ErrMsgs.serviceBuilder_noId)
		if (type == null)		throw IocErr(ErrMsgs.serviceBuilder_noType(id))
		if (builder == null)	throw IocErr(ErrMsgs.serviceBuilder_noBuilder(id))

		aliasTypes?.each { 
			if (it.fits(type).not && type.fits(it).not)
				throw IocErr(ErrMsgs.serviceBuilder_aliasTypeDoesNotFitType(it, type))
		}
		
		return ServiceDefImpl {
			it.id				= this.id
			it.serviceIds		= Str[this.id].addAll(this.aliases ?: Str#.emptyList)
			it.type				= this.type
			it.serviceTypes		= Type[this.type].addAll(this.aliasTypes ?: Type#.emptyList)
			it.declaredScopes	= this.declaredScopes ?: Str#.emptyList
			it.matchedScopes	= this.matchedScopes
			it.builderFuncRef	= Unsafe(this.builder)
			it.contribFuncsRef	= Unsafe(contribDefs?.map |def -> |Configuration| | { def.configFunc })
			it.buildHooksRef	= Unsafe(buildContribs)
		}		
	}

	override Str toStr() { id ?: "ID not set" }
}
