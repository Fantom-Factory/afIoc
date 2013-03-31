
internal const class RegistryImpl : Registry, ObjLocator {
	private const static Log log := Utils.getLog(RegistryImpl#)
	
	private const ConcurrentState 			conState			:= ConcurrentState(RegistryState#)
	private const static Str 				builtInModuleId		:= "BuiltIn Module"
	private const RegistryShutdownHubImpl 	registryShutdownHub	:= RegistryShutdownHubImpl()
	private const Str:Module				modules
	
	new make(OpTracker tracker, ModuleDef[] moduleDefs) {
		serviceIdToModule := Str:Module[:]
		modules := [:]

		tracker.track("Defining Built-In services") |->| {
			services := ServiceDef:Obj?[:]
			
			services[makeBuiltInServiceDef("registry", Registry#)] = this 
			services[makeBuiltInServiceDef("registryShutdownHub", RegistryShutdownHub#)] = registryShutdownHub
			
			services[StandardServiceDef() {
				it.serviceId 	= "ctorFieldInjector"
				it.moduleId		= builtInModuleId
				it.serviceType 	= |This|#
				it.scope		= ScopeDef.perInjection
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

			modules[builtInModuleId] = builtInModule
			services.keys.each {
				serviceIdToModule[it.serviceId] = builtInModule			
			}
		}

		tracker.track("Consolidating module definitions") |->| {
			iModules 	:= modules.toImmutable
			iIdToModule	:= serviceIdToModule.toImmutable
			modules = getMyState |state| {
				mModules 	:= iModules.rw
				mIdToModule	:= iIdToModule.rw
				
				moduleDefs.each |moduleDef| {
					module := ModuleImpl(this, moduleDef)
					mModules[moduleDef.moduleId] = module

					moduleDef.serviceDefs.keys.each |serviceId| {
						if (mIdToModule.containsKey(serviceId)) {
							existingDef 	:= mIdToModule[serviceId].serviceDef(serviceId)
							conflictingDef 	:= module.serviceDef(serviceId)
							throw IocErr(IocMessages.serviceIdConflict(serviceId, existingDef, conflictingDef))
						}
						mIdToModule[serviceId] = module
					}				
				}
				
				return mModules.toImmutable
			}
		}
		
		this.modules = modules
		// TODO: contributions
//        validateContributeDefs(moduleDefs);
	}
	
	// ---- Registry Methods ----------------------------------------------------------------------
	
	override This startup() {
		withMyState |state| {
			state.startupLock.lock
		}
		// TODO: do service startup loading
		return this
	}

	override This shutdown() {
		withMyState |state| {
			state.shutdownLock.lock
		}

		registryShutdownHub.fireRegistryDidShutdown()
		
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
        ServiceDef[] serviceDefs := modules.vals.map |module| {
			module.serviceDef(serviceId)
		}.exclude { it == null }

		if (serviceDefs.isEmpty) 
            throw IocErr(IocMessages.serviceIdNotFound(serviceId))
		
		if (serviceDefs.size > 1)
			throw WtfErr("Multiple services defined for service id $serviceId")
		
		serviceDef := serviceDefs[0]
		return getService(ctx, serviceDef)
	}

	override Obj trackDependencyByType(InjectionCtx ctx, Type dependencyType) {
        ServiceDef[] serviceDefs := modules.vals.map |module| {
			module.serviceDefsByType(dependencyType)
		}.flatten

		// TODO: if not service found, ask other object locators / injection providers

		if (serviceDefs.isEmpty)
			throw IocErr(IocMessages.noServiceMatchesType(dependencyType))
		if (serviceDefs.size > 1)
			throw IocErr(IocMessages.manyServiceMatches(dependencyType, serviceDefs.map { it.serviceId }))

		serviceDef := serviceDefs[0]
		serviceId  := serviceDefs[0].serviceId
		ctx.log("Found Service '$serviceId'")

		return getService(ctx, serviceDef)
	}

	override Obj trackAutobuild(InjectionCtx ctx, Type type) {
		return InjectionUtils.autobuild(ctx, type)
	}

	override Obj trackInjectIntoFields(InjectionCtx ctx, Obj object) {
		return InjectionUtils.injectIntoFields(ctx, object, false)
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
	
	private Void withMyState(|RegistryState| state) {
		conState.withState(state)
	}

	private Obj? getMyState(|RegistryState -> Obj| state) {
		conState.getState(state)
	}
	
	ServiceDef makeBuiltInServiceDef(Str serviceId, Type serviceType) {
		BuiltInServiceDef() {
			it.serviceId = serviceId
			it.moduleId = builtInModuleId
			it.serviceType = serviceType
			it.scope = ScopeDef.perApplication
		}
	}
}

internal class RegistryState {
	OneShotLock 			startupLock 		:= OneShotLock(IocMessages.registryStarted)
	OneShotLock 			shutdownLock 		:= OneShotLock(IocMessages.registryShutdown)
}
