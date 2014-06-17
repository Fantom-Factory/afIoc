using concurrent::Future
using afPlastic::PlasticCompiler

internal const class RegistryImpl : Registry, ObjLocator {
	private const static Log log := Utils.getLog(RegistryImpl#)

	private const OneShotLock 				startupLock 	:= OneShotLock(IocMessages.registryStarted)
	private const OneShotLock 				shutdownLock	:= OneShotLock(IocMessages.registryShutdown)
	private const Str:Module				modules
	private const Module[]					modulesWithServices	// a cache for performance reasons
	private const DependencyProviders?		depProSrc
	private const Duration					startTime
	override const Str:Obj?					options
	
	new make(OpTracker tracker, ModuleDef[] moduleDefs, [Str:Obj?] options) {
		this.startTime					= tracker.startTime
		this.options					= options
		Str:Module serviceIdToModule 	:= Utils.makeMap(Str#, Module#)
		Str:Module moduleIdToModule		:= Utils.makeMap(Str#, Module#)		
		threadLocalManager 				:= ThreadLocalManagerImpl()
		
		// new up Built-In services ourselves (where we can) to cut down on debug noise
		tracker.track("Defining Built-In services") |->| {
			services := ServiceDef:Obj?[:]
			
			services[BuiltInServiceDef() {
				it.serviceType 		= Registry#
			}] = this

			// RegistryStartup needs to be perThread so non-const listeners can be injected into it
			services[BuiltInServiceDef() {
				it.serviceType 		= RegistryStartup#
				it.scope			= ServiceScope.perThread
				it.serviceBuilder	= ServiceDef.fromCtorAutobuild(it, RegistryStartupImpl#)
			}] = null

			services[BuiltInServiceDef() {
				it.serviceType 		= RegistryShutdown#
				it.serviceBuilder	= ServiceDef.fromCtorAutobuild(it, RegistryShutdownImpl#)
			}] = null
			
			services[BuiltInServiceDef() {
				it.serviceId 		= IocConstants.ctorItBlockBuilder
				it.serviceType 		= |This|#
				it.scope			= ServiceScope.perInjection
				it.description 		= "$it.serviceId : Autobuilt. Always."
				it.serviceBuilder	= |->Obj| {
					InjectionUtils.makeCtorInjectionPlan(InjectionTracker.building.serviceImplType)
				}
			}] = null

			services[BuiltInServiceDef() {
				it.serviceType 		= DependencyProviders#
				it.serviceBuilder	= ServiceDef.fromCtorAutobuild(it, DependencyProvidersImpl#)
			}] = null
 
			services[BuiltInServiceDef() {
				it.serviceType 		= ServiceOverrides#
				it.serviceBuilder	= ServiceDef.fromCtorAutobuild(it, ServiceOverridesImpl#)
			}] = null

			services[BuiltInServiceDef() {
				it.serviceType 		= ServiceStats#
			}] = ServiceStatsImpl(this)

			services[BuiltInServiceDef() {
				it.serviceType 		= ServiceProxyBuilder#
				it.serviceBuilder	= ServiceDef.fromCtorAutobuild(it, ServiceProxyBuilderImpl#)
			}] = null

			services[BuiltInServiceDef() {
				it.serviceType 		= PlasticCompiler#
				it.serviceBuilder	= ServiceDef.fromCtorAutobuild(it, PlasticCompiler#)
			}] = null

			services[BuiltInServiceDef() {
				it.serviceType 		= AspectInvokerSource#
				it.serviceBuilder	= ServiceDef.fromCtorAutobuild(it, AspectInvokerSourceImpl#)
			}] = null

			services[BuiltInServiceDef() {
				it.serviceType 		= ThreadLocalManager#
			}] = threadLocalManager

			services[BuiltInServiceDef() {
				it.serviceType 		= RegistryMeta#
			}] = RegistryMetaImpl(options, moduleDefs.map { it.moduleType })

			services[BuiltInServiceDef() {
				it.serviceType 		= LogProvider#
			}] = LogProviderImpl()

			services[BuiltInServiceDef() {
				it.serviceType 		= ActorPools#
				it.serviceBuilder	= ServiceDef.fromCtorAutobuild(it, ActorPoolsImpl#)
			}] = null

			builtInModule := ModuleImpl(this, threadLocalManager, IocConstants.builtInModuleId, services)

			moduleIdToModule[IocConstants.builtInModuleId] = builtInModule
			services.keys.each {
				serviceIdToModule[it.serviceId] = builtInModule			
			}
		}

		tracker.track("Consolidating module definitions") |->| {
			moduleDefs.each |moduleDef| {
				module := ModuleImpl(this, threadLocalManager, moduleDef)
				moduleIdToModule[moduleDef.moduleId] = module

				// ensure services aren't defined twice
				moduleDef.serviceDefs.keys.each |serviceId| {
					if (serviceIdToModule.containsKey(serviceId)) {
						existingDef 	:= serviceIdToModule[serviceId].serviceDefByQualifiedId(serviceId)
						conflictingDef 	:= module.serviceDefByQualifiedId(serviceId)
						throw IocErr(IocMessages.serviceIdConflict(serviceId, existingDef, conflictingDef))
					}
					serviceIdToModule[serviceId] = module
				}				
			}
		}		

		// set before we validate the contributions
		this.modules = moduleIdToModule
		this.modulesWithServices = modules.vals.findAll |module| { module.hasServices }
		
		tracker.track("Validating contribution definitions") |->| {
			moduleDefs.each {
				it.contributionDefs.each {
					if (!it.optional) {	// no warnings / errors for optional contributions
						if (it.serviceId != null)
							if (serviceDefById(it.serviceId) == null)
								throw IocErr(IocMessages.contributionMethodServiceIdDoesNotExist(it.method, it.serviceId))
						if (it.serviceType != null)
							if (serviceDefByType(it.serviceType) == null)
								throw IocErr(IocMessages.contributionMethodServiceTypeDoesNotExist(it.method, it.serviceType))
					}
				}
			}
		}

		tracker.track("Validating advice definitions") |->| {
			advisableServices := serviceIdToModule.keys.findAll { serviceDefById(it).proxiable }
			moduleDefs.each {
				it.adviceDefs.each |adviceDef| {
					if (adviceDef.optional)
						return
					matches := advisableServices.any |serviceId| { 
						adviceDef.matchesServiceId(serviceId)  
					}
					if (!matches)
						throw IocErr(IocMessages.adviceDoesNotMatchAnyServices(adviceDef, advisableServices))
				}
			}
		}
		

		InjectionTracker.withCtx(this, tracker) |->Obj?| {   
			tracker.track("Applying service overrides") |->| {
				overrides := ((ServiceOverrides) trackServiceById(ServiceOverrides#.qname)).overrides
				overrides.each |builder, serviceId| {
					serviceDefById(serviceId).overrideBuilder(builder)
				}
			}
			
			depProSrc = trackServiceById(DependencyProviders#.qname)
			return null
		}
	}


	// ---- Registry Methods ----------------------------------------------------------------------

	override This startup() {
		startupLock.lock

		buildTime := (Duration.now - startTime).toMillis.toLocale("#,###")
		then 	:= Duration.now
		
		// Do dat startup!
		startup := (RegistryStartup) serviceById(RegistryStartup#.qname)
		startup.startup(OpTracker())
		startupTime	:= (Duration.now - then).toMillis.toLocale("#,###")

		msg		:= ""
		
		if (!options.get("suppressStartupServiceList", false)) {
			stats := this.stats.vals.sort |s1, s2| { s1.serviceId <=> s2.serviceId }
			srvcs := "\n\n${stats.size} Services:\n\n"
			maxId := (Int) stats.reduce(0) |size, stat| { ((Int) size).max(stat.serviceId.size) }
			unreal:= 0
			stats.each {
				srvcs	+= it.serviceId.padl(maxId) + ": ${it.lifecycle}\n"
				if (it.lifecycle == ServiceLifecycle.DEFINED)
					unreal++
			}
			perce := (100d * unreal / stats.size).toLocale("0.00")
			srvcs += "\n${perce}% of services are unrealised (${unreal}/${stats.size})\n"
			msg   += srvcs
		}
		
		if (!options.get("suppressStartupBanner", false)) {
			title := Utils.banner(options["bannerText"])
			title += "IoC Registry built in ${buildTime}ms and started up in ${startupTime}ms\n"
			msg   += title
		}
		
		if (!msg.trim.isEmpty)
			log.info(msg)

		return this
	}
	
	override This shutdown() {
		then 		:= Duration.now
		shutdownHub := (RegistryShutdown)	serviceById(RegistryShutdown#.qname)
		threadMan 	:= (ThreadLocalManager)	serviceById(ThreadLocalManager#.qname)
		actorPools	:= (ActorPools) 	 	serviceById(ActorPools#.qname)

		// Registry shutdown commencing...
		shutdownHub.shutdown
		shutdownLock.lock

		// Registry shutdown complete.
		threadMan.cleanUpThread
		modules.each { it.shutdown }
		actorPools[IocConstants.systemActorPool].stop.join(10sec)
		
		shutdownTime	:= (Duration.now - then).toMillis.toLocale("#,###")
		log.info("IoC shutdown in ${shutdownTime}ms")
		
		log.info("\"Goodbye!\" from afIoc!")
		
		return this
	}

	override Obj serviceById(Str serviceId) {
		return Utils.stackTraceFilter |->Obj| {
			shutdownLock.check
			return InjectionTracker.withCtx(this, null) |->Obj?| {   
				return InjectionTracker.track("Locating service by ID '$serviceId'") |->Obj| {
					return trackServiceById(serviceId)
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
			logServiceCreation(RegistryImpl#, "Autobuilding $type2.qname")
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
			logServiceCreation(RegistryImpl#, "Injecting dependencies into fields of $object.typeof.qname")
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

	// ---- ObjLocator Methods --------------------------------------------------------------------

	override Obj trackServiceById(Str serviceId) {
		serviceDef 
			:= serviceDefById(serviceId) 
			?: throw IocErr(IocMessages.serviceIdNotFound(serviceId))
		return getService(serviceDef, false)
	}

	override Obj getService(ServiceDef serviceDef, Bool returnReal) {
		// thinking of extending serviceDef to return the service with a 'makeOrGet' func
		modules[serviceDef.moduleId].service(serviceDef, returnReal)
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
			return getService(serviceDef, false)			
		}

		config := InjectionTracker.provideConfig(dependencyType)
		if (config != null) {
			InjectionTracker.logExpensive |->Str| { "Found Configuration '$config.typeof.signature'" }
			return config
		}

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
		serviceDef := StandardServiceDef() {
			it.serviceId 		= "${type.name}Autobuild"
			it.moduleId			= ""
			it.serviceType 		= type
			it.serviceImplType 	= implType	// the important bit
			it.scope			= ServiceScope.perInjection
			it.description 		= "$type.qname : Autobuild"
			it.serviceBuilderRef.val = |->Obj?| { return null }.toImmutable
		}		
		
		return InjectionTracker.withServiceDef(serviceDef) |->Obj?| {
			return InjectionUtils.autobuild(implType, ctorArgs, fieldVals)
		}
	}

	override Obj trackCreateProxy(Type mixinType, Type? implType, Obj?[]? ctorArgs, [Field:Obj?]? fieldVals) {
		spb := (ServiceProxyBuilder) trackServiceById(ServiceProxyBuilder#.qname)
		
		serviceTypes := ServiceBinderImpl.verifyServiceImpl(mixinType, implType)
		mixinT 	:= serviceTypes[0] 
		implT 	:= serviceTypes[1]
		
		if (!mixinT.isMixin)
			throw IocErr(IocMessages.bindMixinIsNot(mixinT))

		// create a dummy serviceDef
		serviceDef := StandardServiceDef() {
			it.serviceId 		= "${mixinT.name}CreateProxy"
			it.moduleId			= ""
			it.serviceType 		= mixinT
			it.serviceImplType 	= implT
			it.scope			= ServiceScope.perInjection
			it.description 		= "$mixinT.qname : Create Proxy"
			it.serviceBuilderRef.val = |->Obj| { autobuild(implT, ctorArgs, fieldVals) }.toImmutable
		}

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
		serviceDef := modulesWithServices.eachWhile { it.serviceDefByQualifiedId(serviceId) }
		if (serviceDef != null)
			return serviceDef

		serviceDefs := (ServiceDef[]) modulesWithServices.map |module| {
			module.serviceDefsById(serviceId)
		}.flatten

		if (serviceDefs.size > 1)
			throw WtfErr(IocMessages.multipleServicesDefined(serviceId))
		
		return serviceDefs.isEmpty ? null : serviceDefs.first
	}

	override ServiceDef? serviceDefByType(Type serviceType) {
		serviceDefs := (ServiceDef[]) modulesWithServices.map |module| {
			module.serviceDefsByType(serviceType)
		}.flatten

		if (serviceDefs.size > 1) {
			// if exists, return the default service, the one with the qname as its serviceId 
			lastChance := serviceDefs.find { it.serviceId.equalsIgnoreCase(serviceType.qname) }
			return lastChance ?: throw IocErr(IocMessages.manyServiceMatches(serviceType, serviceDefs.map { it.serviceId }))
		}

		return serviceDefs.isEmpty ? null : serviceDefs[0]
	}

	override Contribution[] contributionsByServiceDef(ServiceDef serviceDef) {
		modules.vals.map {
			it.contributionsByServiceDef(serviceDef)
		}.flatten
	}

	override AdviceDef[] adviceByServiceDef(ServiceDef serviceDef) {
		modules.vals.map {
			it.adviceByServiceDef(serviceDef)
		}.flatten
	}

	override Void logServiceCreation(Type log, Str msg) {
		// Option defaults to 'false' as Ioc ideally should run quietly in the background and not 
		// interfere with the running of your app.
		if (options["logServiceCreation"] == true)
			// e could have set afIoc log level to WARN but then we wouldn't get the banner at startup.
			Utils.getLog(log).info(msg)
	}

	override Str:ServiceStat stats() {
		stats := Str:ServiceStat[:]	{ caseInsensitive = true }
		modules.each { stats.addAll(it.serviceStats) }
		return stats
	}	
}
