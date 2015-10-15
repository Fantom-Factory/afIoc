using concurrent::AtomicInt
using concurrent::AtomicRef

** (Service) - 
** The top level IoC object that holds service definitions and the root scope.
** 
** The 'Registry' instance may be dependency injected.  
@Js
const mixin Registry {
	
	** Destroys all active scopes and shuts down the registry.
	abstract This shutdown()

	** Returns the *root* scope.
	abstract Scope rootScope()
	
	** Returns the current *active* scope.
	abstract Scope activeScope()
	
	** Returns a map of all defined scopes, keyed by scope ID.
	abstract Str:ScopeDef scopeDefs()
	
	** Returns a map of all defined services, keyed by service ID.
	abstract Str:ServiceDef	serviceDefs()

	** Returns a pretty printed list of service definitions. 
	** This is logged to standard out at registry startup. 
	** Remove the startup contribution to prevent the logging:
	** 
	** pre>
	** syntax: fantom
	** regBuilder.onRegistryStartup() |Configuration config| {
	**     config.remove("afIoc.logServices")
	** }
	** <pre
	abstract Str printServices()

	** Returns the Alien-Factory ASCII art banner.
	** This is logged to standard out at registry startup. 
	** Remove the startup contribution to prevent the logging:
	** 
	** pre>
	** syntax: fantom
	** regBuilder.onRegistryStartup() |Configuration config| {
	**     config.remove("afIoc.logBanner")
	** }
	** <pre
	abstract Str printBanner()
	
	// used by Reflux to set the default active scope (to uiThread)
	** Sets the default active scope. Defaults to *root scope*.
	@NoDoc
	abstract Scope? setDefaultScope(Scope? defaultScope)
	
	@NoDoc @Deprecated { msg="Use 'rootScope.build()' instead" }
	Obj autobuild(Type type, Obj?[]? ctorArgs := null, [Field:Obj?]? fieldVals := null) {
		rootScope.build(type, ctorArgs, fieldVals)
	}

	@NoDoc @Deprecated { msg="Removed without replacement" }
	This startup() { this }

	@NoDoc @Deprecated { msg="Use 'rootScope.inject()' instead" }
	Obj injectIntoFields(Obj obj) {
		rootScope.inject(obj)
	}

	@NoDoc @Deprecated { msg="Use 'rootScope.callMethod()' instead" }
	Obj? callMethod(Method method, Obj? instance, Obj?[]? args := null) {
		rootScope.callMethod(method, instance, args)
	}

	@NoDoc @Deprecated { msg="Use 'rootScope.serviceById()' instead" }
	Obj? serviceById(Str serviceId, Bool checked := true) {
		rootScope.serviceById(serviceId, checked)
	}

	@NoDoc @Deprecated { msg="Use 'rootScope.serviceByType()' instead" }
	Obj? dependencyByType(Type objType, Bool checked := true) {
		rootScope.serviceByType(objType, checked)
	}
}

@Js
internal const class RegistryImpl : Registry {
	static 
	const AtomicInt				instanceCount	 := AtomicInt(0)
	const OneShotLock 			shuttingdownLock := OneShotLock(ErrMsgs.registryShutdown, RegistryShutdownErr#)
	const OneShotLock 			shutdownLock	 := OneShotLock(ErrMsgs.registryShutdown, RegistryShutdownErr#)
	const Str:ScopeDefImpl		scopeDefs_
	const Str:ServiceDefImpl	serviceDefs_
	const ScopeImpl				rootScope_
	const AutoBuilder			autoBuilder		// keep this handy for optimisation reasons
	const Str:Str[]				scopeIdLookup
	const Str:[Type:Str[]]		scopeTypeLookup
	const ScopeImpl				builtInScope
	const Unsafe				shutdownHooksRef
	const RegistryMeta			regMeta
	const ActiveScopeStack		activeScopeStack
	const ServiceInjectStack	serviceInjectStack
	const AtomicRef				defScopeRef		:= AtomicRef()

	override const Str:ScopeDef		scopeDefs
	override const Str:ServiceDef	serviceDefs

	new make(Duration buildStart, Str:ScpDef scopeDefs_, Str:SrvDef srvDefs, Type[] moduleTypes, [Str:Obj?] options, Func[] startupHooks, Func[] shutdownHooks) {
		instanceCount.incrementAndGet
		activeScopeStack	= ActiveScopeStack(instanceCount.val)
		serviceInjectStack	= ServiceInjectStack(instanceCount.val)

		this.shutdownHooksRef	= Unsafe(shutdownHooks)
		this.scopeDefs_	 		= scopeDefs_.map |def -> ScopeDefImpl| { def.toScopeDef }
		
		scopeIdLookup	:= Str:Str[][:] 			{ it.caseInsensitive = true }
		scopeTypeLookup	:= Str:[Type:Str[]][:]		{ it.caseInsensitive = true }

		this.scopeDefs_.each |scopeDef| {
			idLookup	:= Str[,]
			typeLookup	:= Type:Str[][:]
			srvDefs.each |SrvDef srvDef| {
				srvId := srvDef.id ?: ""
				if (srvDef.matchesScope(scopeDef)) {
					idLookup.add(srvId)
					srvDef.serviceTypes.each {
						typeLookup.getOrAdd(it) { Str[,] }.add(srvId)
					}
					srvDef.matchedScopes.add(scopeDef.id)
				}
			}
			scopeIdLookup[scopeDef.id] 	 = idLookup
			scopeTypeLookup[scopeDef.id] = typeLookup
		}
		
		this.scopeIdLookup 		= scopeIdLookup
		this.scopeTypeLookup	= scopeTypeLookup
		this.serviceDefs_		= srvDefs.map |srvDef->ServiceDefImpl| { srvDef.toServiceDef.validate(this) }
		
		// sort scopeDefs and serviceDefs alphabetically - it's a slower lookup, so keep them in a different ref
		scopeKeys := this.scopeDefs_.keys.sort
		scopeDefs := Str:ScopeDef[:] { it.ordered = true }
		scopeKeys.each { scopeDefs[it] = this.scopeDefs_[it] }
		this.scopeDefs = scopeDefs

		serviceKeys := this.serviceDefs_.keys.sort
		serviceDefs := Str:ServiceDef[:] { it.ordered = true }
		serviceKeys.each { serviceDefs[it] = this.serviceDefs_[it] }
		this.serviceDefs = serviceDefs


	
		// ---- Fire up the Scopes ----

		now				:= Duration.now
		buildDuration	:= now - buildStart
		startStart		:= now
		
		builtInScopeDef	:= findScopeDef("builtIn", null)
		builtInScope	= ScopeImpl(this, null, builtInScopeDef)
		
		rootScopeDef	:= findScopeDef("root", builtInScope)
		rootScope_	 	= ScopeImpl(this, builtInScope, rootScopeDef)
		defScopeRef.val	= rootScope_

	
		
		// ---- Create Dependency Providers ----

		dependencyProviders := DependencyProviders(Str:DependencyProvider[
			"afIoc.autobuild"	: AutobuildProvider(),
			"afIoc.func"		: FuncProvider(),
			"afIoc.log"			: LogProvider(),
			"afIoc.scope"		: ScopeProvider(),

			"afIoc.config"		: ConfigProvider(),
			"afIoc.funcArg"		: FuncArgProvider(),
			"afIoc.service"		: ServiceProvider(),
			"afIoc.ctorItBlock"	: CtorItBlockProvider()
		]) 
		autoBuilder			= AutoBuilder([:], dependencyProviders)
		regMeta				= RegistryMetaImpl(options, moduleTypes)

		builtInScope.instanceById(Registry#				.qname, [,], true).setInstance(this)
		builtInScope.instanceById(RegistryMeta#			.qname, [,], true).setInstance(regMeta)
		builtInScope.instanceById(DependencyProviders#	.qname, [,], true).setInstance(dependencyProviders)
		builtInScope.instanceById(AutoBuilder#			.qname, [,], true).setInstance(autoBuilder)
		
		sysDepProInst	:= builtInScope.instanceById(DependencyProviders#.qname, [,], true)
		userDepPro		:= (DependencyProviders) autoBuilder.autobuild(rootScope_, DependencyProviders#, null, null, DependencyProviders#.qname)
		sysDepProInst.setInstance(userDepPro)
		
		autoBuilderInst	:= builtInScope.instanceById(AutoBuilder#.qname, [,], true)
		autoBuilder		= autoBuilder.autobuild(rootScope_, AutoBuilder#, [userDepPro], null, AutoBuilder#.qname)
		autoBuilderInst.setInstance(autoBuilder)


		
		// ---- Startup Registry ----
		
		config	:= ConfigurationImpl(rootScope_, Str:|Scope|#, "afIoc::Registry.onStartup")
		startupHooks.each {
			it.call(config)
			config.cleanupAfterMethod
		}
		hooks := (Str:Func) config.toMap
		
		// ensure system messages are printed at the end 
		order	:= "afIoc.logServices afIoc.logBanner".split
		hooks.keys.sort |k1, k2| {
			(order.index(k1) ?: -1) <=> (order.index(k2) ?: -1)
		}.each {
			hooks[it].call(rootScope_)
		}
		
		if (hooks.containsKey("afIoc.logStartupTimes")) {
			startDuration	:= Duration.now - startStart
			buildTime 		:= buildDuration.toMillis.toLocale("#,###")
			startupTime 	:= startDuration.toMillis.toLocale("#,###")
			msg 			:= "IoC Registry built in ${buildTime}ms and started up in ${startupTime}ms\n"
			Registry#.pod.log.info(msg)
		}
	}
	
	override This shutdown() {
		if (shuttingdownLock.lock) return this

		// call the Shutdown hooks first so services (and shutdown contributions!) can still access the registry
		then 	:= Duration.now
		config	:= ConfigurationImpl(rootScope_, Str:|Scope|#, "afIoc::Registry.onShutdown")
		configs	:= (Func[]) shutdownHooksRef.val
		configs.each {
			it.call(config)
			config.cleanupAfterMethod
		}
		hooks := (Str:Func) config.toMap

		sayGoodbye := hooks.containsKey("afIoc.sayGoodbye")
			
		hooks.each { it.call(rootScope_) }
		
		// destroy all active scopes and their children...!
		scope := (Scope?) activeScope
		while (scope != null) {
			scope.destroy
			scope = scope.parent
		}

		// ensure the core scopes are destoyed - for wotever reason they may not have been part of the scope hierarchy
		rootScope_.destroy
		builtInScope.destroy
		
		if (sayGoodbye) {
			log			 := Registry#.pod.log
			shutdownTime := (Duration.now - then).toMillis.toLocale("#,###")
			log.info("IoC shutdown in ${shutdownTime}ms")
			log.info("IoC says, \"Goodbye!\"")
		}

		// allow services (and shutdown contributions!) access the registry until it *has* been shutdown
		shutdownLock.lock
		return this
	}
	
	override Scope rootScope() {
		shutdownLock.check
		return rootScope_
	}

	override Scope activeScope() {
		shutdownLock.check
		return (activeScopeStack.peek ?: defScopeRef.val) ?: rootScope_
	}
	
	override Str printServices() {
		print := "\n"
		
		buckets := groupBy(serviceDefs.vals) |ServiceDef def->Obj| { def.type.pod.name }
		buckets = buckets.keys.sort.reduce(Str:Obj[:] { it.ordered = true }) |Str:Obj map, key| { map[key] = buckets[key] }
		
		
		maxSize := 0
		buckets.each |ServiceDef[] serviceDefs, Str podName| {
			serSize := (Int) serviceDefs.reduce(0) |size, stat| { ((Int) size).max(stat.id.replace("${podName}::", "").size) }
			maxSize = maxSize.max(serSize)
		}
		
		built := 0
		buckets.each |ServiceDef[] serviceDefs, Str podName| {
			srvcs	:= "" 
			noOfPub := 0
			noOfPri := 0
			serviceDefs.each |ServiceDefImpl def| {
				pub := def.serviceTypes.any { isPublic }
				if (pub) {
					sep	  := def.noOfInstancesBuilt > 0 ? "|" : ":"
					srvcs += def.id.replace("${podName}::", "").padl(maxSize + 2) + "${sep} " + def.matchedScopes.join(", ") + "\n"
					noOfPub++
				} else
					noOfPri++
				if (def.noOfInstancesBuilt > 0) built++
			}
			
			print += noOfPub == 1
				? "\n1 public service in ${podName}"
				: "\n${noOfPub} public services in ${podName}"
			if (noOfPri > 0)
				print += " (and ${noOfPri} private)"
			print += ":\n\n"
			print += srvcs
		}

		stats := serviceDefs.vals
		perce := (100f * built / stats.size).toLocale("0.00")
		print += "\n${perce}% of services were built on startup (${built}/${stats.size})\n"
		
		return print
	}
	
	// see http://fantom.org/forum/topic/2296
	static Obj:Obj[] groupBy(Obj[] list, |Obj item, Int index->Obj| keyFunc) {
		list.reduce(Obj:Obj[][:] { it.ordered = true}) |Obj:Obj[] bucketList, val, i| {
			key := keyFunc(val, i)
			bucketList.getOrAdd(key) { Obj[,] }.add(val)
			return bucketList
		}
	}
	
	override Str printBanner() {
		heading := (Str) (regMeta.options["afIoc.bannerText"] ?: "Err...")
		title := "\n"
		title += Str<|   ___    __                 _____        _                  
		                / _ |  / /_____  _____    / ___/__  ___/ /_________  __ __ 
		               / _  | / // / -_|/ _  /===/ __// _ \/ _/ __/ _  / __|/ // / 
		              /_/ |_|/_//_/\__|/_//_/   /_/   \_,_/__/\__/____/_/   \_, /  
		              |>
		first := true
		while (!heading.isEmpty) {
			banner := heading.size > 52 ? heading[0..<52] : heading
			heading = heading[banner.size..-1]
			banner = first ? (banner.padl(52, ' ') + " /___/   \n") : (banner.padr(52, ' ') + "\n")
			title += banner
			first = false
		}
		title 	+= "\n"

		return title
	}
	
	override Scope? setDefaultScope(Scope? scope) {
		this.defScopeRef.val = scope
		return scope
	}
	
	ScopeDefImpl findScopeDef(Str scopeId, ScopeImpl? currentScope) {
		scopeDef := (ScopeDefImpl) (scopeDefs_.find |def| { def.matchesId(scopeId)  } ?: throw ArgNotFoundErr(ErrMsgs.scope_scopeNotFound(scopeId), scopeDefs_.keys))

		scope	:= currentScope
		scopes	:= ScopeImpl[,]
		if (scope != null) scopes.add(scope)
		while (scope?.parent != null) {
			scope = scope.parent
			scopes.insert(0, scope)
		}

		// there's no technical reason to disallow scope nesting, but I can't think of a reason why you would want it!?
		// Ergo, it's probably a user error.
		if (scopes.any { it.scopeDef.matchesId(scopeId) })
			throw IocErr(ErrMsgs.scope_scopesMayNotBeNested(scopeId, scopes.map { it.id }))

		if (currentScope != null && !scopeDef.threaded && currentScope.scopeDef.threaded)
			throw IocErr(ErrMsgs.scope_invalidScopeNesting(scopeId, currentScope.id))

		return scopeDef
	}
}