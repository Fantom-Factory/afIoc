using concurrent
using afPlastic::PlasticCompiler

internal const class RegistryImpl : Registry, ObjLocator {
	private const static Log log := Utils.getLog(RegistryImpl#)

	private const OneShotLock 			startupLock 	:= OneShotLock(IocMessages.registryStarted)
	private const OneShotLock 			shutdownLock	:= OneShotLock(|->| { throw IocShutdownErr(IocMessages.registryShutdown) })
	private const Str:ServiceDef		serviceDefs
	private const ThreadLocalManager	threadLocalMgr
	private const CachingTypeLookup		typeLookup
	private const Duration				startTime
			const AtomicBool			logServices		:= AtomicBool(false)
			const AtomicBool			logBanner		:= AtomicBool(false)
			const AtomicBool			sayGoodbye		:= AtomicBool(false)	

	override const InjectionUtils		injectionUtils
	override const ServiceBuilders		serviceBuilders
	override const DependencyProviders	dependencyProviders
	
	new make(OpTracker tracker, ModuleDef[] moduleDefs, [Str:Obj?] options) {
		this.startTime	= tracker.startTime
		threadLocalMgr 	= ThreadLocalManagerImpl()
		injectionUtils	= InjectionUtils(this)
		serviceBuilders	= ServiceBuilders(injectionUtils)
		serviceDefs		:= (Str:ServiceDef) Utils.makeMap(Str#, ServiceDef#)
		builtInModuleDef:= (ModuleDef?) null

		readyMade 		:= [
			Registry#			: this,
			RegistryMeta#		: RegistryMetaImpl(options, moduleDefs.map { it.moduleType }),
			ThreadLocalManager#	: threadLocalMgr,
			InjectionUtils#		: injectionUtils
		]
		
		// create a temp internal version for creating Depdendency Providers with
		this.dependencyProviders = DependencyProvidersImpl.makeInternal([
			AutobuildProvider(this),
			LocalProvider(threadLocalMgr),
			LogProviderImpl(),
			ConfigProvider(),
			CtorItBlockProvider(this),
			ServiceProvider(this)
		])

		// new up Built-In services ourselves (where we can) to cut down on debug noise
		tracker.track("Defining Built-In services") |->| {
			builtInModuleDef = ModuleDef(tracker, IocModule#)
			builtInModuleDef.serviceDefs.each { it.builtIn = true }
			moduleDefs.add(builtInModuleDef)	// so we can override LogProvider			
		}

		srvDefs	:= (SrvDef[]) moduleDefs.map { it.serviceDefs  }.flatten
		ovrDefs	:= (SrvDef[]) moduleDefs.map { it.overrideDefs }.flatten

		// this IoC trace makes more sense when we throw dup id errs
		tracker.track("Consolidating service definitions") |->| {
			// we could use Map.addList(), but do it the long way round so we get a nice error on dups
			services	:= Str:SrvDef[:] { caseInsensitive = true}
			srvDefs.each {
				if (services.containsKey(it.id))
					throw IocErr(IocMessages.serviceAlreadyDefined(it.id, it, services[it.id]))
				services[it.id] = it
			}

			// we could use Map.addList(), but do it the long way round so we get a nice error on dups
			overrides	:= Str:SrvDef[:] { caseInsensitive = true}
			ovrDefs.each {
				if (overrides.containsKey(it.id))
					throw IocErr(IocMessages.onlyOneOverrideAllowed(it.id, it, overrides[it.id]))
				overrides[it.id] = it
			}

			tracker.track("Applying service overrides") |->| {
				keys := Utils.makeMap(Str#, Str#)
				services.keys.each { keys[it] = it }
	
				// normalise keys -> map all keys to orig key and apply overrides
				// code nabbed from Configuration
				found		:= true
				while (!overrides.isEmpty && found) {
					found = false
					overrides = overrides.exclude |over, existingKey| {
						overrideKey := over.overrideRef
						if (keys.containsKey(existingKey)) {
							if (keys.containsKey(overrideKey))
								throw IocErr(IocMessages.overrideAlreadyDefined(over.overrideRef, over, services[keys[existingKey]]))

							keys[overrideKey] = keys[existingKey]
							found = true
							
							tracker.log("'${overrideKey}' overrides '${existingKey}'")
							srvDef := services[keys[existingKey]]						
							srvDef.applyOverride(over)
	
							return true
						} else {
							return false
						}
					}
				}

				overrides = overrides.exclude { it.overrideOptional }
	
				if (!overrides.isEmpty) {
					keysNotFound := overrides.keys.join(", ")
					throw ServiceNotFoundErr(IocMessages.serviceIdNotFound(keysNotFound), services.keys)
				}
			}
		}

		tracker.track("Compiling service configuration methods") |->| {
			moduleDefs.each |moduleDef| {
				moduleDef.contribDefs.each |contribDef| {
					matches := srvDefs.findAll |def| { 
						contribDef.matchesSvrDef(def)
					}
					// should only really ever be the one match!
					matches.each { it.addContribDef(contribDef) }
					
					if (!contribDef.optional && matches.isEmpty)
						throw ServiceNotFoundErr(IocMessages.contributionServiceNotFound(contribDef.method, contribDef.srvId), srvDefs)
				}
			}
		}

		tracker.track("Validating advice definitions") |->| {
			advisableServices := srvDefs.findAll { it.proxy != ServiceProxy.never }
			moduleDefs.each {
				it.adviceDefs.each |adviceDef| {
					matches := advisableServices.findAll |def| { 
						adviceDef.matchesSvrDef(def)  
					}
					if (matches.isEmpty && !adviceDef.optional)
						throw ServiceNotFoundErr(IocMessages.adviceDoesNotMatchAnyServices(adviceDef), advisableServices)
					matches.each { it.addAdviceDef(adviceDef) }
				}
			}
		}

		tracker.track("Solidifying service definitions") |->| {
			moduleDefs.each |moduleDef| {
				moduleDef.serviceDefs.each |def| {
					impl := readyMade.get(def.type)
					sdef := def.toServiceDef(this, threadLocalMgr, impl)
					serviceDefs[sdef.serviceId] = sdef
				}
			}
		}		

		InjectionTracker.withCtx(tracker) |->| {
			this.serviceDefs 		= serviceDefs
			this.typeLookup			= CachingTypeLookup(serviceDefs.vals)
			this.dependencyProviders= trackServiceById(DependencyProviders#.qname, true)
		}
	}


	// ---- Registry Methods ----------------------------------------------------------------------

	override This startup() {
		shutdownLock.check
		startupLock.lock

		buildTime	:= (Duration.now - startTime).toMillis.toLocale("#,###")
		then 		:= Duration.now
		
		// Do dat startup!
		startup 	:= (RegistryStartup) serviceById(RegistryStartup#.qname)
		startup.startup(OpTracker())
		startupTime	:= (Duration.now - then).toMillis.toLocale("#,###")

		// We're alive! Shout it out to the world!
		msg			:= ""

		// we do this here (and not in the contribution) because we want to print last
		// (to get the most upto date stats)
		if (logServices.val)
			msg += startup.printServiceList
		
		if (logBanner.val) {
			msg += startup.printBanner
			msg += "IoC Registry built in ${buildTime}ms and started up in ${startupTime}ms\n"
		}
		
		if (!msg.isEmpty)
			log.info(msg)

		return this
	}
	
	override This shutdown() {
		shutdownLock.check
		then 		:= Duration.now
		shutdownHub := (RegistryShutdown)	serviceById(RegistryShutdown#.qname)
		threadMan 	:= (ThreadLocalManager)	serviceById(ThreadLocalManager#.qname)
		actorPools	:= (ActorPools) 	 	serviceById(ActorPools#.qname)

		// Registry shutdown commencing...
		shutdownHub.shutdown
		shutdownLock.lock

		// Registry shutdown complete.
		threadMan.cleanUpThread
		serviceDefs.each { it.shutdown }
		actorPools[IocConstants.systemActorPool].stop.join(10sec)
		
		shutdownTime := (Duration.now - then).toMillis.toLocale("#,###")
		if (sayGoodbye.val) {
			log.info("IoC shutdown in ${shutdownTime}ms")
			log.info("\"Goodbye!\" from afIoc!")
		}
		return this
	}

	override Obj? serviceById(Str serviceId, Bool checked := true) {
		return Utils.stackTraceFilter |->Obj?| {
			shutdownLock.check
			return InjectionTracker.track("Locating service by ID '$serviceId'") |->Obj?| {
				return trackServiceById(serviceId, checked)
			}
		}
	}

	override Obj? dependencyByType(Type dependencyType, Bool checked := true) {
		return Utils.stackTraceFilter |->Obj?| {
			shutdownLock.check
			return InjectionTracker.track("Locating dependency by type '$dependencyType.qname'") |->Obj?| {
				return trackDependencyByType(dependencyType, checked)
			}
		}
	}

	** see http://fantom.org/sidewalk/topic/2149
	override Obj autobuild(Type type2, Obj?[]? ctorArgs := null, [Field:Obj?]? fieldVals := null) {
		return Utils.stackTraceFilter |->Obj| {
			shutdownLock.check
			return trackAutobuild(type2, ctorArgs, fieldVals)
		}
	}
	
	override Obj createProxy(Type mixinType, Type? implType := null, Obj?[]? ctorArgs := null, [Field:Obj?]? fieldVals := null) {
		return Utils.stackTraceFilter |->Obj?| {
			shutdownLock.check
			return InjectionTracker.track("Creating proxy for ${mixinType.qname}") |->Obj?| {
				return trackCreateProxy(mixinType, implType, ctorArgs, fieldVals)
			}
		}
	}

	override Obj injectIntoFields(Obj object) {
		return Utils.stackTraceFilter |->Obj| {
			shutdownLock.check
			return InjectionTracker.track("Injecting dependencies into fields of ${object.typeof.qname}") |->Obj?| {
				return injectionUtils.injectIntoFields(object)
			}
		}
	}

	override Obj? callMethod(Method method, Obj? instance, Obj?[]? providedMethodArgs := null) {
		try {
			return Utils.stackTraceFilter |->Obj?| {
				shutdownLock.check
				return InjectionTracker.track("Calling method '$method.signature'") |->Obj?| {
					return injectionUtils.callMethod(method, instance, providedMethodArgs)
				}
			}
		} catch (IocErr iocErr) {
			unwrapped := Utils.unwrap(iocErr)
			// if unwrapped is still an IocErr then re-throw the original
			throw (unwrapped is IocErr) ? iocErr : unwrapped
		}
	}

	override Str:ServiceDefinition serviceDefinitions() {
		defs := Str:ServiceDefinition[:] { ordered = true }
		serviceDefs.keys.sort.each { defs[it] = serviceDefs[it].toServiceDefinition }
		return defs
	}	

	// ---- ObjLocator Methods --------------------------------------------------------------------

	override Obj? trackServiceById(Str serviceId, Bool checked) {
		serviceDef := serviceDefById(serviceId)
		if (serviceDef == null)
			return checked ? throw ServiceNotFoundErr(IocMessages.serviceIdNotFound(serviceId), serviceIds) : null
		return serviceDef.getService
	}

	Obj? trackDependencyByType(Type dependencyType, Bool checked) {
		return InjectionTracker.doingDependencyByType(dependencyType) |ctx->Obj?| {
			return dependencyProviders.provideDependency(ctx, checked)
		}
	}

	override Obj trackAutobuild(Type type, Obj?[]? ctorArgs, [Field:Obj?]? fieldVals) {
		Type? implType := type
		
		if (implType.isAbstract) {
			implType 	= Type.find("${type.qname}Impl", false)
			if (implType == null)
				throw IocErr(IocMessages.autobuildTypeHasToInstantiable(type))
		}
		
		existing := serviceDefByType(implType) 
		if (existing != null)
			log.warn(IocMessages.warnAutobuildingService(existing.serviceId, existing.serviceType))
		
		sid		:= "${type.name}(Autobuild)"
		ctor 	:= InjectionUtils.findAutobuildConstructor(implType)
		builder	:= threadLocalMgr.createRef("autobuild")
		// so we can pass mutable parameters into Autobuilds - they're gonna be used straight away
		builder.val = serviceBuilders.fromCtorAutobuild(sid, ctor, ctorArgs, fieldVals)
		
		serviceDef := ServiceDef(this) {
			it.serviceId 		= sid
			it.serviceType 		= type
			it.serviceScope		= ServiceScope.perThread	// because it's used straight away
			it.serviceProxy		= ServiceProxy.never
			it.description 		= "$type.qname : Autobuild"
			it.serviceBuilder	= |->Obj| {
				func := (|->Obj|) builder.val
				builder.cleanUp
				return func.call 
			}
		}
		
		return serviceDef.getService
	}

	override Obj trackCreateProxy(Type mixinType, Type? implType, Obj?[]? ctorArgs, [Field:Obj?]? fieldVals) {
		spb := (ServiceProxyBuilder) trackServiceById(ServiceProxyBuilder#.qname, true)
		
		serviceTypes := ServiceBinderImpl.verifyServiceImpl(mixinType, implType)
		mixinT 	:= serviceTypes[0] 
		implT 	:= serviceTypes[1]
		
		if (!mixinT.isMixin)
			throw IocErr(IocMessages.onlyMixinsCanBeProxied(mixinT))

		existing := serviceDefByType(mixinType) 
		if (existing != null)
			log.warn(IocMessages.warnAutobuildingService(existing.serviceId, existing.serviceType))

		sid		:= "${mixinT.name}(CreateProxy)"
		ctor 	:= InjectionUtils.findAutobuildConstructor(implT)
		scope	:= mixinT.isConst ? ServiceScope.perApplication : ServiceScope.perThread
		builder	:= ObjectRef(threadLocalMgr.createRef("createProxy"), scope, null)
		builder.val	= serviceBuilders.fromCtorAutobuild(sid, ctor, ctorArgs, fieldVals)

		serviceDef := ServiceDef(this) {
			it.serviceId 		= sid
			it.serviceType 		= mixinT
			it.serviceScope		= scope
			it.serviceProxy		= ServiceProxy.always
			it.description 		= "$mixinT.qname : Create Proxy"
			it.serviceBuilder	= |->Obj| {
				func := (|->Obj|) builder.val
				builder.cleanUp
				return func.call 
			}
		}
		return serviceDef.getService
	}
	
	ServiceDef? serviceDefById(Str serviceId) {
		// attempt a qualified search first
		serviceDef := serviceDefs[serviceId]
		if (serviceDef != null)
			return serviceDef

		serviceDefs := serviceDefs.vals.findAll { it.matchesId(serviceId) }
		if (serviceDefs.size > 1)
			throw IocErr(IocMessages.multipleServicesDefined(serviceId, serviceDefs.map { it.serviceId }))
		
		return serviceDefs.isEmpty ? null : serviceDefs.first
	}

	override Bool typeMatchesService(Type serviceType) {
		!typeLookup.findChildren(serviceType).isEmpty
	}

	override ServiceDef? serviceDefByType(Type serviceType) {
		serviceDefs := (ServiceDef[]) typeLookup.findChildren(serviceType)

		if (serviceDefs.size > 1) {
			// if exists, return the default service, the one with the qname as its serviceId 
			lastChance := serviceDefs.find { it.serviceId.equalsIgnoreCase(serviceType.qname) }
			return lastChance ?: throw IocErr(IocMessages.manyServiceMatches(serviceType, serviceDefs.map { it.serviceId }))
		}

		return serviceDefs.isEmpty ? null : serviceDefs[0]
	}
	
	override Str[] serviceIds() {
		serviceDefs.keys
	}
}
