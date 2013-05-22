
internal const class RegistryImpl : Registry, ObjLocator {
	private const static Log log := Utils.getLog(RegistryImpl#)
	
	private const ConcurrentState 			conState			:= ConcurrentState(RegistryState#)
	private const Str:Module				modules
	private const DependencyProviderSource?	depProSrc
	private const ServiceOverride?			serviceOverrides
	private const Duration					startTime
	
	new make(OpTracker tracker, ModuleDef[] moduleDefs) {
		startTime			= tracker.startTime
		serviceIdToModule 	:= Str:Module[:]
		moduleIdToModule	:= Str:Module[:]
		
		// new up Built-In services ourselves (where we can) to cut down on debug noise
		tracker.track("Defining Built-In services") |->| {
			services := ServiceDef:Obj?[:]
			
			services[BuiltInServiceDef() {
				it.serviceId 	= ServiceIds.registry
				it.serviceType 	= Registry#
			}] = this

			// RegistryStartup needs to be perThread so non-const listeners can be injected into it
			services[BuiltInServiceDef() {
				it.serviceId 	= ServiceIds.registryStartup
				it.serviceType 	= RegistryStartup#
				it.scope		= ServiceScope.perThread
				it.source		= ServiceDef.fromCtorAutobuild(it, RegistryStartupImpl#)
			}] = null

			services[BuiltInServiceDef() {
				it.serviceId 	= ServiceIds.registryShutdownHub
				it.serviceType 	= RegistryShutdownHub#
			}] = RegistryShutdownHubImpl()
			
			services[BuiltInServiceDef() {
				it.serviceId 	= ServiceIds.ctorFieldInjector
				it.serviceType 	= |This|#
				it.scope		= ServiceScope.perInjection
				it.description 	= "'$it.serviceId' : Autobuilt. Always."
				it.source		= |InjectionCtx ctx->Obj| {
					InjectionUtils.makeCtorInjectionPlan(ctx, ctx.building.serviceImplType)
				}
			}] = null

			services[BuiltInServiceDef() {
				it.serviceId 	= ServiceIds.dependencyProviderSource
				it.serviceType 	= DependencyProviderSource#
				it.source		= ServiceDef.fromCtorAutobuild(it, DependencyProviderSourceImpl#)
			}] = null

			services[BuiltInServiceDef() {
				it.serviceId 	= ServiceIds.serviceOverride
				it.serviceType 	= ServiceOverride#
				it.source		= ServiceDef.fromCtorAutobuild(it, ServiceOverrideImpl#)
			}] = null

			services[BuiltInServiceDef() {
				it.serviceId 	= ServiceIds.serviceStats
				it.serviceType 	= ServiceStats#
			}] = ServiceStatsImpl(this)

			services[BuiltInServiceDef() {
				it.serviceId 	= ServiceIds.plasticPodCompiler
				it.serviceType 	= PlasticPodCompiler#
				it.serviceImplType 	= PlasticPodCompiler#	// TODO: make mixin
				it.source		= ServiceDef.fromCtorAutobuild(it, PlasticPodCompiler#)
			}] = null

			services[BuiltInServiceDef() {
				it.serviceId 	= ServiceIds.serviceProxyBuilder
				it.serviceType 	= ServiceProxyBuilder#
				it.serviceImplType 	= ServiceProxyBuilder#	// TODO: make mixin
				it.source		= ServiceDef.fromCtorAutobuild(it, ServiceProxyBuilder#)
			}] = null

			builtInModule := ModuleImpl(this, ServiceIds.builtInModuleId, services)

			moduleIdToModule[ServiceIds.builtInModuleId] = builtInModule
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
		
		title := Utils.banner("Alien-Factory IoC v$typeof.pod.version.toStr")
		title += "IoC started up in ${millis}ms\n"
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
		Utils.stackTraceFilter |->Obj| {
			shutdownLockCheck
			ctx := InjectionCtx(this)
			return ctx.track("Locating service by ID '$serviceId'") |->Obj| {
				trackServiceById(ctx, serviceId)
			}
		}
	}

	override Obj dependencyByType(Type dependencyType) {
		Utils.stackTraceFilter |->Obj| {
			shutdownLockCheck
			ctx := InjectionCtx(this)
			return ctx.track("Locating dependency by type '$dependencyType.qname'") |->Obj| {
				trackDependencyByType(ctx, dependencyType)
			}
		}
	}

	** see http://fantom.org/sidewalk/topic/2149
	override Obj autobuild(Type type2, Obj?[] ctorArgs := Obj#.emptyList) {
		Utils.stackTraceFilter |->Obj| {
			shutdownLockCheck
			IocHelper.doLogServiceCreation(RegistryImpl#, "Autobuilding $type2.qname") 
			return trackAutobuild(InjectionCtx(this), type2, ctorArgs)
		}
	}

	override Obj injectIntoFields(Obj object) {
		Utils.stackTraceFilter |->Obj| {
			shutdownLockCheck
			IocHelper.doLogServiceCreation(RegistryImpl#, "Injecting dependencies into fields of $object.typeof.qname")
			return trackInjectIntoFields(InjectionCtx(this), object)
		}
	}


	// ---- ObjLocator Methods --------------------------------------------------------------------

	override Obj trackServiceById(InjectionCtx ctx, Str serviceId) {
		serviceDef 
			:= serviceDefById(serviceId) 
			?: throw IocErr(IocMessages.serviceIdNotFound(serviceId))
		return getService(ctx, serviceDef, false)
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
			return getService(ctx, serviceDef, false)			
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

	override Obj trackAutobuild(InjectionCtx ctx, Type type, Obj?[] ctorArgs) {
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
			return InjectionUtils.autobuild(ctx, type, ctorArgs)
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

	override Obj getService(InjectionCtx ctx, ServiceDef serviceDef, Bool forceCreate) {
		service := serviceOverrides?.getOverride(serviceDef.serviceId)
		if (service != null) {
			ctx.log("Found override for service '${serviceDef.serviceId}'")
			return service
		}

		// thinking of extending serviceDef to return the service with a 'makeOrGet' func
		return modules[serviceDef.moduleId].service(ctx, serviceDef.serviceId, forceCreate)
	}


	// ---- Helper Methods ------------------------------------------------------------------------
	
	internal Str:ServiceStat stats() {
		stats := Str:ServiceStat[:]	{ caseInsensitive = true }
		modules.each { stats.addAll(it.serviceStats) }
		return stats
	}

	private Void shutdownLockCheck() {
		withMyState |state| {
			state.shutdownLock.check
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
