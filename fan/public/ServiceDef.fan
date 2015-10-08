using concurrent::AtomicInt

@Js
const mixin ServiceDef {
	
	abstract Str		id()
	abstract Type		type()
	abstract Str[]		aliases()
	abstract Type[]		aliasTypes()
	abstract Str[]		declaredScopes()
	abstract Str[]		matchedScopes()
	abstract Int		noOfInstancesBuilt()
	
	abstract Bool matchesId(Str serviceId)
	abstract Bool matchesType(Type serviceType)
}

@Js
internal const class ServiceDefImpl : ServiceDef {
	
	override const Str		id
	override const Type		type
	override const Str[]	declaredScopes
	override const Str[]	matchedScopes
	override const Str[]	aliases
	override const Type[]	aliasTypes
			const Str[]		serviceIds
			const Type[]	serviceTypes
			const Unsafe?	contribFuncsRef		// Unsafe because Javascript can't hold immutable funcs
			const Unsafe	builderFuncRef		// Unsafe because Javascript can't hold immutable funcs
			const Unsafe?	buildHooksRef		// Unsafe because Javascript can't hold immutable funcs
			const AtomicInt	noOfInstancesRef	:= AtomicInt(0)

	new make(|This|in) {
		in(this)
		this.type 			= this.type.toNonNullable
		this.serviceTypes	= this.serviceTypes.map |t->Type| { t.toNonNullable } 
		this.aliases		= this.serviceIds[1..-1]
		this.aliasTypes		= this.serviceTypes[1..-1]
	}
	
	|Scope->Obj| builderFunc() { builderFuncRef.val }

	|Configuration|[]? contribFuncs() {
		contribFuncsRef?.val
	}

	override Int noOfInstancesBuilt() {
		noOfInstancesRef.val
	}
	
	override Bool matchesId(Str serviceId) {
		serviceIds.any { it.equalsIgnoreCase(serviceId) }
	}

	override Bool matchesType(Type serviceType) {
		serviceTypes.any { it == serviceType }
	}

	Obj build(Scope currentScope) {
		instance	:=  builderFunc.call(currentScope)
		noOfInstancesRef.incrementAndGet
		return instance
	}

	Void callBuildHooks(Scope currentScope, Obj instance) {
		configs	:= (Func[]?) buildHooksRef?.val
		if (configs != null && configs.isEmpty.not) {
			config	:= ConfigurationImpl(currentScope, Str:|Scope, ServiceDef, Obj|#, "afIoc::Scope.onCreate")
			configs.each {
				it.call(config)
				config.cleanupAfterMethod
			}
			hooks := (Str:Func) config.toMap
			hooks.each { it.call(currentScope, this, instance) }
		}
	}

	This validate(RegistryImpl registry) {
		declaredScopes.exclude |s1| { registry.scopeDefs_.keys.any |s2| { s1.equalsIgnoreCase(s2) } } {
			if (it.isEmpty.not) 
				throw IocErr(ErrMsgs.serviceBuilder_scopesNotFound(id, it))
		}

		if (matchedScopes.isEmpty) {
			declaredScopes.each { 
				if (type.isConst.not && registry.scopeDefs_[it].threaded.not)
					throw IocErr(ErrMsgs.serviceBuilder_scopeIsThreaded(id, it))
			}
			throw IocErr(ErrMsgs.serviceBuilder_noScopesMatched(id, registry.scopeDefs_.keys))
		}

		return this
	}
	
	Obj gatherConfiguration(Scope currentScope, Type configType) {
		
		config := ConfigurationImpl(currentScope, configType, id)
		
		contribFuncs?.each | |Configuration| func| {
			func.call(config)
			config.cleanupAfterMethod
		}

		if (configType.name == "List")
			return config.toList
		if (configType.name == "Map")
			return config.toMap
		throw Err("WTF: ${configType.name} is neither a List nor a Map!?")
	}	

	@NoDoc
	override Str toStr() { serviceIds.first }
}
