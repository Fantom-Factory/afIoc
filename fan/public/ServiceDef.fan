using concurrent::AtomicInt

** Definition of a Service.
** 'ServiceDefs' are returned from [Registry.serviceDefs()]`Registry.serviceDefs`.
@Js
const mixin ServiceDef {

	** The service's unique ID.
	abstract Str	id()

	** The Type of the service.
	abstract Type	type()

	** Any aliases the service is also known as (IDs).
	abstract Str[]	aliases()

	** Any aliases the service is also known as (Types).
	abstract Type[]	aliasTypes()

	** The scopes this service was declared with.
	abstract Str[]	declaredScopes()

	** The scopes this service has been matched with (and is able to be created in).
	abstract Str[]	matchedScopes()

	** The number of services (to date) that have been built.
	abstract Int	noOfInstancesBuilt()

	** Returns 'true' if the service ID or any aliases matches the given ID.
	abstract Bool 	matchesId(Str serviceId)

	** Returns 'true' if the service type or any aliases matches the given type.
	abstract Bool 	matchesType(Type serviceType)
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
				throw ArgNotFoundErr(ErrMsgs.serviceBuilder_scopesNotFound(id, it), registry.scopeDefs_.keys)
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
	override Str toStr() {
		str := serviceIds.first
		if (aliases.size > 0 || aliasTypes.size > 0) {
			alias := aliases.dup.addAll(aliasTypes.map { it.qname })
			str   += " (aliases: " + alias.join(", ") + ")"			
		}
		return str
	}
}
