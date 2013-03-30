
internal const class RegistryImpl : ConcurrentState, Registry, ObjLocator {
	private const static Log log := Utils.getLog(RegistryImpl#)
	
	private const static Str 				builtInModuleId		:= "BuiltIn Module"
	private const RegistryShutdownHubImpl 	registryShutdownHub	:= RegistryShutdownHubImpl()
	private const Str:Module				modules
	
	new make(OpTracker tracker, ModuleDef[] moduleDefs) : super(RegistryState#) {
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
				it.source		= |OpTracker trakker, ObjLocator objLoc->Obj| {
					|Obj service| {
						trakker.track("Injecting via Ctor Field Injector") {
							// TODO: Cannot reflectively set const fields, even in the ctor
							// see http://fantom.org/sidewalk/topic/2119
							InjectionUtils.injectIntoFields(trakker, objLoc, service, false, ScopeDef.perInjection)
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
		return OpTracker().track("Locating service by ID '$serviceId'") |tracker| {
			trackServiceById(tracker, serviceId)
		}
	}

	override Obj dependencyByType(Type dependencyType) {
		shutdownLockCheck
		return OpTracker().track("Locating dependency by type '$dependencyType.qname'") |tracker| {
			trackDependencyByType(tracker, dependencyType)
		}
	}

	override Obj autobuild(Type type) {
		shutdownLockCheck
		log.info("Autobuilding $type.qname")
		return trackAutobuild(OpTracker(), type)
	}

	override Obj injectIntoFields(Obj object) {
		shutdownLockCheck
		log.info("Injecting dependencies into fields of $object.typeof.qname")
		return trackInjectIntoFields(OpTracker(), object)
	}

	// ---- ObjLocator Methods --------------------------------------------------------------------

	override Obj trackServiceById(OpTracker tracker, Str serviceId) {
        ServiceDef[] serviceDefs := modules.vals.map |module| {
			module.serviceDef(serviceId)
		}.exclude { it == null }

		if (serviceDefs.isEmpty) 
            throw IocErr(IocMessages.serviceIdNotFound(serviceId))
		
		if (serviceDefs.size > 1)
			throw WtfErr("Multiple services defined for service id $serviceId")
		
		// thinking of extending serviceDef to return the service with a 'makeOrGet' func
        return modules[serviceDefs[0].moduleId].service(tracker, serviceId)
	}
	
	override Obj trackDependencyByType(OpTracker tracker, Type dependencyType) {
        ServiceDef[] serviceDefs := modules.vals.map |module| {
			module.serviceDefsByType(dependencyType)
		}.flatten

		// TODO: if not service found, ask other object locators
		
		if (serviceDefs.isEmpty)
			throw IocErr(IocMessages.noServiceMatchesType(dependencyType))
		if (serviceDefs.size > 1)
			throw IocErr(IocMessages.manyServiceMatches(dependencyType, serviceDefs.map { it.serviceId }))

		serviceId := serviceDefs[0].serviceId
		tracker.log("Found Service '$serviceId'")

		// thinking of extending serviceDef to return the service with a 'makeOrGet' func
        return modules[serviceDefs[0].moduleId].service(tracker, serviceId)
	}

	override Obj trackAutobuild(OpTracker tracker, Type type) {
		return InjectionUtils.autobuild(tracker, this, type, null)
	}
	
	override Obj trackInjectIntoFields(OpTracker tracker, Obj object) {
		return InjectionUtils.injectIntoFields(tracker, this, object, false, null)
	}
	
	// ---- Helper Methods ------------------------------------------------------------------------

	private Void shutdownLockCheck() {
		withMyState |state| {
			state.shutdownLock.check
		}		
	}
	
	private Void withMyState(|RegistryState| state) {
		super.withState(state)
	}

	private Obj? getMyState(|RegistryState -> Obj| state) {
		super.getState(state)
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
