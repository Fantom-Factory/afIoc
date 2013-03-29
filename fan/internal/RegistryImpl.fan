
internal class RegistryImpl : Registry, ObjLocator {
	private const static Log log := Utils.getLog(RegistryImpl#)
	
	private OneShotLock 			startupLock 		:= OneShotLock(IocMessages.registryStarted)
	private OneShotLock 			shutdownLock 		:= OneShotLock(IocMessages.registryShutdown)
	private RegistryShutdownHubImpl registryShutdownHub	:= RegistryShutdownHubImpl()

	private Module[]				modules				:= [,]
	
	new make(OpTracker tracker, ModuleDef[] moduleDefs) {
		serviceIdToModule := Str:Module[:]
		
		tracker.track("Defining Built-In services") |->| {
			builtInModule := BuiltInModule()
			builtInModule.addBuiltInService("registry", Registry#, this)
			builtInModule.addBuiltInService("registryShutdownHub", RegistryShutdownHub#, registryShutdownHub)
		// TODO: add some stats - e.g. hits - to the scoreboard
	//        addBuiltin(SERVICE_ACTIVITY_SCOREBOARD_SERVICE_ID, ServiceActivityScoreboard#, tracker)
			
			modules.add(builtInModule)
			builtInModule.serviceDefs.each {
				serviceIdToModule[it.serviceId] = builtInModule			
			}
		}

		tracker.track("Consolidating module definitions") |->| {
			moduleDefs.each |moduleDef| {
				module := StandardModule(this, moduleDef)
				modules.add(module)
				
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
		
		// TODO: contributions
//        validateContributeDefs(moduleDefs);
	}
	
	// ---- Registry Methods ----------------------------------------------------------------------
	
	override This startup() {
		startupLock.lock
		// TODO: do service startup loading
		return this
	}

	override This shutdown() {
		shutdownLock.lock
		registryShutdownHub.fireRegistryDidShutdown()
		
		// destroy all internal refs
		modules.clear
		
		return this
	}

	override Obj serviceById(Str serviceId) {
		shutdownLock.check
		return OpTracker().track("Locating service by ID '$serviceId'") |tracker| {
			trackServiceById(tracker, serviceId)
		}
	}

	override Obj dependencyByType(Type dependencyType) {
		shutdownLock.check
		return OpTracker().track("Locating dependency by type '$dependencyType.qname'") |tracker| {
			trackDependencyByType(tracker, dependencyType)
		}
	}

	override Obj autobuild(Type type) {
		shutdownLock.check
		log.info("Autobuilding $type.qname")
		return trackAutobuild(OpTracker(), type)
	}

	override Obj injectIntoFields(Obj object) {
		shutdownLock.check
		log.info("Injecting dependencies into fields of $object.typeof.qname")
		return trackInjectIntoFields(OpTracker(), object)
	}

	// ---- ObjLocator Methods --------------------------------------------------------------------

	override Obj trackServiceById(OpTracker tracker, Str serviceId) {
        Obj[] services := modules.map {
			it.service(tracker, serviceId)
		}.exclude { it == null }

		if (services.isEmpty) 
            throw IocErr(IocMessages.serviceIdNotFound(serviceId))
		
		if (services.size > 1)
			throw WtfErr("Multiple services defined for service id $serviceId")
		
        return services[0]
	}
	
	override Obj trackDependencyByType(OpTracker tracker, Type dependencyType) {
        Str[] serviceIds := modules.map |module| {
			module.findServiceIdsForType(dependencyType)
		}.flatten	// FIXME: how to empty lists flatten?

		// FUTURE: if no service found, ask other object locators
		if (serviceIds.isEmpty)
			throw IocErr(IocMessages.noServiceMatchesType(dependencyType))
		if (serviceIds.size > 1)
			throw IocErr(IocMessages.manyServiceMatches(dependencyType, serviceIds))

		serviceId := serviceIds.get(0)
		tracker.log("Found Service '$serviceId'")
        return trackServiceById(tracker, serviceId)
	}

	override Obj trackAutobuild(OpTracker tracker, Type type) {
		return InjectionUtils.autobuild(tracker, this, type)
	}
	
	override Obj trackInjectIntoFields(OpTracker tracker, Obj object) {
		return InjectionUtils.injectIntoFields(tracker, this, object)
	}
}
