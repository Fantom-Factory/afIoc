
internal const class RegistryImpl : Registry, ObjLocator {
	private const static Log log := Utils.getLog(RegistryImpl#)
	
	private const ConcurrentState 			conState			:= ConcurrentState(RegistryState#)
	private const static Str 				builtInModuleId		:= "BuiltInModule"
	private const Str:Module				modules
	private const DependencyProviderSource?	depProSrc
	private const ServiceOverride?			serviceOverrides
	
	private const Duration					startTime
	private const Int						noOfServices
	
	new make(OpTracker tracker, ModuleDef[] moduleDefs) {
		startTime			= tracker.startTime
		serviceIdToModule 	:= Str:Module[:]
		moduleIdToModule	:= Str:Module[:]
		
		tracker.track("Defining Built-In services") |->| {
			services := ServiceDef:Obj?[:]			
			services[makeBuiltInServiceDef(ServiceIds.registry, Registry#)] = this 

			// new up Built-In services ourselves to cut down on debug noise
			services[makeBuiltInServiceDef(ServiceIds.registryShutdownHub, RegistryShutdownHub#)] = RegistryShutdownHubImpl()
			
			services[StandardServiceDef() {
				it.serviceId 	= ServiceIds.ctorFieldInjector
				it.moduleId		= builtInModuleId
				it.serviceType 	= |This|#
				it.scope		= ServiceScope.perInjection
				it.description 	= "'$it.serviceId' : Autobuilt. Always."
				it.source		= |InjectionCtx ctx->Obj| {
					InjectionUtils.makeCtorInjectionPlan(ctx, ctx.building.serviceImplType)
				}
			}] = null

			services[StandardServiceDef() {
				it.serviceId 	= ServiceIds.dependencyProviderSource
				it.moduleId		= builtInModuleId
				it.serviceType 	= DependencyProviderSource#
				it.scope		= ServiceScope.perApplication
				it.description 	= "'$it.serviceId' : Built In Service"
				it.source		= ServiceBinderImpl.ctorAutobuild(it, DependencyProviderSourceImpl#)
			}] = null

			services[StandardServiceDef() {
				it.serviceId 	= ServiceIds.serviceOverride
				it.moduleId		= builtInModuleId
				it.serviceType 	= ServiceOverride#
				it.scope		= ServiceScope.perApplication
				it.description 	= "'$it.serviceId' : Built In Service"
				it.source		= ServiceBinderImpl.ctorAutobuild(it, ServiceOverrideImpl#)
			}] = null

			services[makeBuiltInServiceDef(ServiceIds.serviceStats, ServiceStats#)] = ServiceStatsImpl(this)
			
			builtInModule := ModuleImpl(this, builtInModuleId, services)

			moduleIdToModule[builtInModuleId] = builtInModule
			services.keys.each {
				serviceIdToModule[it.serviceId] = builtInModule			
			}
		}

		tracker.track("Consolidating module definitions") |->| {
			moduleDefs.each |moduleDef| {
				module := ModuleImpl(this, moduleDef)
				moduleIdToModule[moduleDef.moduleId] = module

				// ensure services aren't defined twice
				moduleDef.serviceDefs.keys.each |serviceId| {
					if (serviceIdToModule.containsKey(serviceId)) {
						existingDef 	:= serviceIdToModule[serviceId].serviceDef(serviceId)
						conflictingDef 	:= module.serviceDef(serviceId)
						throw IocErr(IocMessages.serviceIdConflict(serviceId, existingDef, conflictingDef))
					}
					serviceIdToModule[serviceId] = module
				}				
			}
		}		

		// set before we validate the contributions
		this.modules = moduleIdToModule		
		
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

		injCtx				:= InjectionCtx(this, tracker)
		depProSrc			= trackServiceById(injCtx, ServiceIds.dependencyProviderSource)
		noOfServices		= serviceIdToModule.size
		serviceOverrides	= trackServiceById(injCtx, ServiceIds.serviceOverride)
	}


	// ---- Registry Methods ----------------------------------------------------------------------

	override This startup() {
		withMyState |state| {
			state.startupLock.lock
		}

		// Do dat startup!
		tracker := OpTracker()
		startup := serviceById(ServiceIds.registryStartup) as RegistryStartupImpl
		startup.go(tracker)
		
		millis	:= (Duration.now - startTime).toMillis.toLocale("#,000")
		
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
		
		title	:= "Alien-Factory IoC v" + typeof.pod.version.toStr + " /___/   "
		title 	= title.padl(61, ' ')
		title = "   ___    __                 _____        _                  
		           / _ |  / /  _____  _____  / ___/__  ___/ /_________  __ __ 
		          / _  | / /_ / / -_|/ _  / / __// _ \\/ _/ __/ _  / __|/ // / 
		         /_/ |_|/___//_/\\__|/_//_/ /_/   \\_,_/__/\\__/____/_/   \\_, /  \n" + title
		title 	+= "\n\n"
		title 	+= "IoC started up in ${millis}ms\n"

		log.info(srvcs + title)
		return this
	}

	override This shutdown() {
		shutdownHub := serviceById(RegistryShutdownHub#.name) as RegistryShutdownHubImpl

		// Registry shutdown commencing...
		shutdownHub.registryWillShutdown

		withMyState |state| {
			state.shutdownLock.lock
		}

		// Registry shutdown complete.
		shutdownHub.registryHasShutdown
		
		// destroy all internal refs
		modules.each { it.clear }
		
		return this
	}

	override Obj serviceById(Str serviceId) {
		shutdownLockCheck
		ctx := InjectionCtx(this)
		return ctx.track("Locating service by ID '$serviceId'") |->Obj| {
			trackServiceById(ctx, serviceId)
		}
	}

	override Obj dependencyByType(Type dependencyType) {
		shutdownLockCheck
		ctx := InjectionCtx(this)
		return ctx.track("Locating dependency by type '$dependencyType.qname'") |->Obj| {
			trackDependencyByType(ctx, dependencyType)
		}
	}

	override Obj autobuild(Type type,
		Obj? a := null, Obj? b := null, Obj? c := null, Obj? d := null,
		Obj? e := null, Obj? f := null, Obj? g := null, Obj? h := null) {
		shutdownLockCheck
		log.info("Autobuilding $type.qname")
		params := Utils.toParamList(a, b, c, d, e, f, g, h)
		return trackAutobuild(InjectionCtx(this), type, params)
	}

	override Obj injectIntoFields(Obj object) {
		shutdownLockCheck
		log.info("Injecting dependencies into fields of $object.typeof.qname")
		return trackInjectIntoFields(InjectionCtx(this), object)
	}


	// ---- ObjLocator Methods --------------------------------------------------------------------

	override Obj trackServiceById(InjectionCtx ctx, Str serviceId) {
		serviceDef 
			:= serviceDefById(serviceId) 
			?: throw IocErr(IocMessages.serviceIdNotFound(serviceId))
		return getService(ctx, serviceDef)
	}

	override Obj trackDependencyByType(InjectionCtx ctx, Type dependencyType) {

		// ask dependency providers first, for they may dictate dependency scope
		dependency := depProSrc?.provideDependency(ctx.providerCtx, dependencyType)
		if (dependency != null) {
			ctx.log("Found Dependency via Provider : '$dependency.typeof'")
			return dependency
		}

		serviceDef := serviceDefByType(dependencyType)
		if (serviceDef != null) {
			ctx.log("Found Service '$serviceDef.serviceId'")
			return getService(ctx, serviceDef)			
		}

		// look for configuration
		dependency = ctx.provideConfig(dependencyType)
		if (dependency != null) {
			ctx.logExpensive |->Str| { "Found Configuration '$dependency.typeof'" }
			return dependency
		}

		// extra info - kill these msgs if they get in the way of refactoring
		if (dependencyType.fits(MappedConfig#))
			throw IocErr(IocMessages.configMismatch(dependencyType, OrderedConfig#))
		if (dependencyType.fits(OrderedConfig#))
			throw IocErr(IocMessages.configMismatch(MappedConfig#, dependencyType))
		
		throw IocErr(IocMessages.noDependencyMatchesType(dependencyType))
	}

	override Obj trackAutobuild(InjectionCtx ctx, Type type, Obj?[] initParams) {
		// create a dummy serviceDef - this will be used by CtorFieldInjector to find the type being built
		serviceDef := StandardServiceDef() {
			it.serviceId 	= "${type.name}Autobuild"
			it.moduleId		= ""
			it.serviceType 	= type
			it.serviceImplType 	= type
			it.scope		= ServiceScope.perInjection
			it.description 	= "$type.qname Autobuild"
			it.source		= |InjectionCtx ctxx->Obj?| { return null }
		}		
		return ctx.withServiceDef(serviceDef) |->Obj?| {
			return InjectionUtils.autobuild(ctx, type, initParams)
		}
	}

	override Obj trackInjectIntoFields(InjectionCtx ctx, Obj object) {
		return InjectionUtils.injectIntoFields(ctx, object)
	}

	override ServiceDef? serviceDefById(Str serviceId) {
		ServiceDef[] serviceDefs := modules.vals.map |module| {
			module.serviceDef(serviceId)
		}.exclude { it == null }

		if (serviceDefs.size > 1)
			throw WtfErr("Multiple services defined for service id $serviceId")
		
		return serviceDefs.isEmpty ? null : serviceDefs[0]
	}

	override ServiceDef? serviceDefByType(Type serviceType) {
		ServiceDef[] serviceDefs := modules.vals.map |module| {
			module.serviceDefsByType(serviceType)
		}.flatten

		if (serviceDefs.size > 1)
			throw IocErr(IocMessages.manyServiceMatches(serviceType, serviceDefs.map { it.serviceId }))

		return serviceDefs.isEmpty ? null : serviceDefs[0]
	}

	override Contribution[] contributionsByServiceDef(ServiceDef serviceDef) {
		modules.vals.map {
			it.contributionsByServiceDef(serviceDef)
		}.flatten
	}


	// ---- Helper Methods ------------------------------------------------------------------------
	
	internal Str:ServiceStat stats() {
		stats := Str:ServiceStat[:]	{ caseInsensitive = true }
		modules.each { stats.addAll(it.serviceStats) }
		return stats
	}

	private Obj getService(InjectionCtx ctx, ServiceDef serviceDef) {
		service := serviceOverrides?.getOverride(serviceDef.serviceId)
		if (service != null) {
			ctx.log("Found override for service '${serviceDef.serviceId}'")
			return service
		}

		// thinking of extending serviceDef to return the service with a 'makeOrGet' func
		return modules[serviceDef.moduleId].service(ctx, serviceDef.serviceId)
	}
	
	private Void shutdownLockCheck() {
		withMyState |state| {
			state.shutdownLock.check
		}		
	}

	private ServiceDef makeBuiltInServiceDef(Str serviceId, Type serviceType, ServiceScope scope := ServiceScope.perApplication) {
		BuiltInServiceDef() {
			it.serviceId = serviceId
			it.moduleId = builtInModuleId
			it.serviceType = serviceType
			it.scope = scope
		}
	}
	
	private Void withMyState(|RegistryState| state) {
		conState.withState(state)
	}

	private Obj? getMyState(|RegistryState -> Obj| state) {
		conState.getState(state)
	}
}

internal class RegistryState {
	OneShotLock 			startupLock 		:= OneShotLock(IocMessages.registryStarted)
	OneShotLock 			shutdownLock 		:= OneShotLock(IocMessages.registryShutdown)
}
