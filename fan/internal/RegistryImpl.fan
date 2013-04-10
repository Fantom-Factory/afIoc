
internal const class RegistryImpl : Registry, ObjLocator {
	private const static Log log := Utils.getLog(RegistryImpl#)
	
	private const ConcurrentState 			conState			:= ConcurrentState(RegistryState#)
	private const static Str 				builtInModuleId		:= "BuiltInModule"
	private const Str:Module				modules
	private const DependencyProviderSource?	depProSrc
	
	new make(OpTracker tracker, ModuleDef[] moduleDefs) {
		serviceIdToModule 	:= Str:Module[:]
		moduleIdToModule	:= Str:Module[:]
		
		tracker.track("Defining Built-In services") |->| {
			services := ServiceDef:Obj?[:]			
			services[makeBuiltInServiceDef("Registry", Registry#)] = this 

			// new up Built-In services ourselves to cut down on debug noise
			services[makeBuiltInServiceDef("RegistryShutdownHub", RegistryShutdownHub#)] = RegistryShutdownHubImpl()
			
			services[StandardServiceDef() {
				it.serviceId 	= "CtorFieldInjector"
				it.moduleId		= builtInModuleId
				it.serviceType 	= |This|#
				it.scope		= ServiceScope.perInjection
				it.description 	= "'$it.serviceId' : Autobuilt. Always."
				it.source		= |InjectionCtx ctx->Obj| {
					InjectionUtils.makeCtorInjectionPlan(ctx, ctx.building.serviceImplType)
				}
			}] = null

			services[StandardServiceDef() {
				it.serviceId 	= "DependencyProviderSource"
				it.moduleId		= builtInModuleId
				it.serviceType 	= DependencyProviderSource#
				it.scope		= ServiceScope.perApplication
				it.description 	= "'$it.serviceId' : Built In Service"
				it.source		= ServiceBinderImpl.ctorAutobuild(it, DependencyProviderSourceImpl#)
			}] = null

		// TODO: add some stats - e.g. hits - to the scoreboard
	//        addBuiltin(SERVICE_ACTIVITY_SCOREBOARD_SERVICE_ID, ServiceActivityScoreboard#, tracker)

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
		
		injCtx		:= InjectionCtx(this, tracker)
		depProSrc	= trackServiceById(injCtx, "DependencyProviderSource")
	}


	// ---- Registry Methods ----------------------------------------------------------------------
	
	override This startup() {
		withMyState |state| {
			state.startupLock.lock
		}
		
		// Do dat startup!
		tracker := OpTracker()
		serviceById(RegistryStartup#.name)->go(tracker)

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

	override Obj autobuild(Type type) {
		shutdownLockCheck
		log.info("Autobuilding $type.qname")
		return trackAutobuild(InjectionCtx(this), type)
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
			ctx.logExpensive |->Str| { "Found Dependency via Provider : '$dependency.typeof'" }
			return dependency
		}
		
		serviceDef := serviceDefByType(dependencyType)
		if (serviceDef != null) {
			ctx.log("Found Service '$serviceDef.serviceId'")
			return getService(ctx, serviceDef)			
		}
		
		// look for configuration
		dependency = ctx.provideDependency(dependencyType)
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

	override Obj trackAutobuild(InjectionCtx ctx, Type type) {
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
			return InjectionUtils.autobuild(ctx, type)
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


	private Obj getService(InjectionCtx ctx, ServiceDef serviceDef) {		
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
