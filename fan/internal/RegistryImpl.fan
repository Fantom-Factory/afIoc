
internal const class RegistryImpl : Registry, ObjLocator {
	private const static Log log := Utils.getLog(RegistryImpl#)
	
	private const ConcurrentState 			conState			:= ConcurrentState(RegistryState#)
	private const static Str 				builtInModuleId		:= "BuiltInModule"
	private const Str:Module				modules
	
	new make(OpTracker tracker, ModuleDef[] moduleDefs) {
		serviceIdToModule 	:= Str:Module[:]
		moduleIdToModule	:= Str:Module[:]

		tracker.track("Defining Built-In services") |->| {
			services := ServiceDef:Obj?[:]			
			services[makeBuiltInServiceDef("registry", Registry#)] = this 

			services[StandardServiceDef() {
				it.serviceId 	= "ctorFieldInjector"
				it.moduleId		= builtInModuleId
				it.serviceType 	= |This|#
				it.scope		= ServiceScope.perInjection
				it.description 	= "'$it.serviceId' : Autobuilt. Always."
				it.source		= |InjectionCtx ctx->Obj| {
					|Obj service| {
						ctx.track("Injecting via Ctor Field Injector") |->| {
							InjectionUtils.injectIntoFields(ctx, service, true)
						}
					}
				}
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

		// Registry shutdown is commencing...
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
		serviceDef := serviceDefByType(dependencyType)
		
		if (serviceDef != null) {
			ctx.log("Found Service '$serviceDef.serviceId'")
			return getService(ctx, serviceDef)			
		}
		
		// look for configuration
		dependency := ctx.provideDependency(dependencyType)
		if (dependency != null) {
			ctx.logExpensive |->Str| { "Found Dependency '$dependency'" }
			return dependency
		}
		
		// TODO: if not service found, ask other object locators / injection providers
		
		throw IocErr(IocMessages.noDependencyMatchesType(dependencyType))
	}

	override Obj trackAutobuild(InjectionCtx ctx, Type type) {
		return InjectionUtils.autobuild(ctx, type)
	}

	override Obj trackInjectIntoFields(InjectionCtx ctx, Obj object) {
		return InjectionUtils.injectIntoFields(ctx, object, false)
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

	private ServiceDef makeBuiltInServiceDef(Str serviceId, Type serviceType) {
		BuiltInServiceDef() {
			it.serviceId = serviceId
			it.moduleId = builtInModuleId
			it.serviceType = serviceType
			it.scope = ServiceScope.perApplication
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
