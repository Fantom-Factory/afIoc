using concurrent
using afPlastic::PlasticCompiler

internal const class RegistryImpl : Registry, ObjLocator {
	private const static Log log := Utils.getLog(RegistryImpl#)

	private const OneShotLock 			startupLock 	:= OneShotLock(IocMessages.registryStarted)
	private const OneShotLock 			shutdownLock	:= OneShotLock(|->| { throw IocShutdownErr(IocMessages.registryShutdown) })
	private const Str:ServiceDef		serviceDefs
	private const DependencyProviders?	depProSrc
	private const Duration				startTime
			const AtomicBool			logServices		:= AtomicBool(false)
			const AtomicBool			logBanner		:= AtomicBool(false)
			const AtomicBool			sayGoodbye		:= AtomicBool(false)	
	
	new make(OpTracker tracker, ModuleDef[] moduleDefs, [Str:Obj?] options) {
		this.startTime	= tracker.startTime
		serviceDefs		:= (Str:ServiceDef) Utils.makeMap(Str#, ServiceDef#)
		threadLocalMgr 	:= ThreadLocalManagerImpl()
		builtInModuleDef:= (ModuleDef?) null

		readyMade 		:= [
			Registry#			: this,
			RegistryMeta#		: RegistryMetaImpl(options, moduleDefs.map { it.moduleType }),
			ThreadLocalManager#	: threadLocalMgr
		]

		// new up Built-In services ourselves (where we can) to cut down on debug noise
		tracker.track("Defining Built-In services") |->| {
			builtInModuleDef = ModuleDef(tracker, IocModule#)
			builtInModuleDef.serviceDefs.each { it.builtIn = true }
			moduleDefs.add(builtInModuleDef)	// so we can override LogProvider			
		}

		srvDefs	:= (SrvDef[]) moduleDefs.map { it.serviceDefs.vals }.flatten
		ovrDefs	:= (SrvDef[]) moduleDefs.map { it.serviceOverrides }.flatten
		
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

		this.serviceDefs = serviceDefs

		InjectionTracker.withCtx(this, tracker) |->Obj?| {
			depProSrc = trackServiceById(DependencyProviders#.qname, true)
			return null
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
			return InjectionTracker.withCtx(this, null) |->Obj?| {   
				return InjectionTracker.track("Locating service by ID '$serviceId'") |->Obj?| {
					return trackServiceById(serviceId, checked)
				}
			}
		}
	}

	override Obj? dependencyByType(Type dependencyType, Bool checked := true) {
		return Utils.stackTraceFilter |->Obj?| {
			shutdownLock.check
			return InjectionTracker.withCtx(this, null) |->Obj?| {
				return InjectionTracker.track("Locating dependency by type '$dependencyType.qname'") |->Obj?| {
					return InjectionTracker.doingDependencyByType(dependencyType) |->Obj?| {
						// as ctx is brand new, this won't return null
						return trackDependencyByType(dependencyType, checked)
					}
				}
			}
		}
	}

	** see http://fantom.org/sidewalk/topic/2149
	override Obj autobuild(Type type2, Obj?[]? ctorArgs := null, [Field:Obj?]? fieldVals := null) {
		return Utils.stackTraceFilter |->Obj| {
			shutdownLock.check
			return InjectionTracker.withCtx(this, null) |->Obj?| {
				return trackAutobuild(type2, ctorArgs, fieldVals)
			}
		}
	}
	
	override Obj createProxy(Type mixinType, Type? implType := null, Obj?[]? ctorArgs := null, [Field:Obj?]? fieldVals := null) {
		return Utils.stackTraceFilter |->Obj?| {
			shutdownLock.check
			return InjectionTracker.withCtx(this, null) |->Obj?| {
				return InjectionTracker.track("Creating proxy for ${mixinType.qname}") |->Obj?| {
					return trackCreateProxy(mixinType, implType, ctorArgs, fieldVals)
				}
			}
		}
	}

	override Obj injectIntoFields(Obj object) {
		return Utils.stackTraceFilter |->Obj| {
			shutdownLock.check
			return InjectionTracker.withCtx(this, null) |->Obj?| {
				return trackInjectIntoFields(object)
			}
		}
	}

	override Obj? callMethod(Method method, Obj? instance, Obj?[]? providedMethodArgs := null) {
		try {
			return Utils.stackTraceFilter |->Obj?| {
				shutdownLock.check
				return InjectionTracker.withCtx(this, null) |->Obj?| {
					return InjectionTracker.track("Calling method '$method.signature'") |->Obj?| {
						return trackCallMethod(method, instance, providedMethodArgs)
					}
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

	override Obj? trackDependencyByType(Type dependencyType, Bool checked) {

		// ask dependency providers first, for they may dictate dependency scope
		ctx := InjectionTracker.injectionCtx
		if (depProSrc?.canProvideDependency(ctx) ?: false) {
			dependency := depProSrc.provideDependency(ctx)
			InjectionTracker.logExpensive |->Str| { "Found Dependency via Provider : '$dependency?.typeof'" }
			return dependency
		}

		serviceDef := serviceDefByType(dependencyType)
		if (serviceDef != null) {
			InjectionTracker.logExpensive |->Str| { "Found Service '$serviceDef.serviceId'" }
			return serviceDef.getService
		}

		config := InjectionTracker.provideConfig(dependencyType)
		if (config != null) {
			InjectionTracker.logExpensive |->Str| { "Found Configuration '$config.typeof.signature'" }
			return config
		}

		// if we had this as a DependencyProvider, then other dependency providers couldn't use ctor injection
		if ((ctx.injectingIntoType != null) && (ctx.dependencyType == |This|#))
			return InjectionUtils.makeCtorInjectionPlan(ctx.injectingIntoType)

		return checked ? throw IocErr(IocMessages.noDependencyMatchesType(dependencyType)) : null
	}

	override Obj trackAutobuild(Type type, Obj?[]? ctorArgs, [Field:Obj?]? fieldVals) {
		Type? implType := type
		
		if (implType.isAbstract) {
			implType 	= Type.find("${type.qname}Impl", false)
			if (implType == null)
				throw IocErr(IocMessages.autobuildTypeHasToInstantiable(type))
		}		
		
		// create a dummy serviceDef - this will be used by CtorItBlockBuilder to find the type being built
		serviceDef := ServiceDef() {
			it.serviceId 		= "${type.name}(Autobuild)"
			it.serviceType 		= type
			it.serviceScope		= type.isConst ? ServiceScope.perApplication : ServiceScope.perThread
			it.serviceProxy		= ServiceProxy.never
			it.description 		= "$type.qname : Autobuild"
			it.serviceBuilder	= safe(ServiceBuilders.fromCtorAutobuild(it, implType, ctorArgs, fieldVals))
		}
		
		return serviceDef.newInstance
	}
	
	// So we can pass mutable parameters into Autobuilds - they're gonna be used straight away
	private static |->Obj| safe(|->Obj| func) {
		unsafe := Unsafe(func) 
		return |->Obj| { unsafe.val->call }
	}

	override Obj trackCreateProxy(Type mixinType, Type? implType, Obj?[]? ctorArgs, [Field:Obj?]? fieldVals) {
		spb := (ServiceProxyBuilder) trackServiceById(ServiceProxyBuilder#.qname, true)
		
		serviceTypes := ServiceBinderImpl.verifyServiceImpl(mixinType, implType)
		mixinT 	:= serviceTypes[0] 
		implT 	:= serviceTypes[1]
		
		if (!mixinT.isMixin)
			throw IocErr(IocMessages.bindMixinIsNot(mixinT))

		// create a dummy serviceDef
		serviceDef := ServiceDef() {
			it.serviceId 		= "${mixinT.name}(CreateProxy)"
			it.serviceType 		= mixinT
			it.serviceScope		= mixinT.isConst ? ServiceScope.perApplication : ServiceScope.perThread
			it.serviceProxy		= ServiceProxy.always
			it.description 		= "$mixinT.qname : Create Proxy"
			it.serviceBuilder	= |->Obj| { autobuild(implT, ctorArgs, fieldVals) }.toImmutable
		}

		// TODO: go through service
		return spb.createProxyForMixin(serviceDef)
	}
	
	override Obj trackInjectIntoFields(Obj object) {
		return InjectionUtils.injectIntoFields(object)
	}

	override Obj? trackCallMethod(Method method, Obj? instance, Obj?[]? providedMethodArgs) {
		return InjectionUtils.callMethod(method, instance, providedMethodArgs)
	}

	override ServiceDef? serviceDefById(Str serviceId) {
		// attempt a qualified search first
		serviceDef := serviceDefs[serviceId]
		if (serviceDef != null)
			return serviceDef

		serviceDefs := serviceDefs.vals.findAll { it.matchesId(serviceId) }
		if (serviceDefs.size > 1)
			throw IocErr(IocMessages.multipleServicesDefined(serviceId, serviceDefs.map { it.serviceId }))
		
		return serviceDefs.isEmpty ? null : serviceDefs.first
	}

	override ServiceDef? serviceDefByType(Type serviceType) {
		serviceDefs := serviceDefs.vals.findAll { it.matchesType(serviceType) }

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
