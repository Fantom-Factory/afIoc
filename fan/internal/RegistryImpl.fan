
** TODO: add some stats - e.g. hits - to the scoreboard
** TODO: internal class RegistryState - methods check to see if reg is started up / shut down, etc... 
internal class RegistryImpl : Registry, ObjLocator {
	private const static Log log := Utils.getLog(RegistryImpl#)
	
	private RegistryShutdownHubImpl registryShutdownHub

	private Str:Obj					builtinServices 	:= Str:Obj[:] 		{ caseInsensitive = true }
	
	private ServiceDef[]			allServiceDefs		:= [,]
	private Module[]				modules				:= [,]
	private Str:Module				serviceIdToModule 	:= Str:Module[:]	{ caseInsensitive = true }
	
	new make(ModuleDef[] moduleDefs) {
		
		moduleDefs.each |def| {   
			logger := Log.get(def.loggerName)
			
			module := ModuleImpl(this, def, logger)
			ServiceDef[] moduleServiceDefs := [,]
			
			def.serviceDefs.keys.each |serviceId| {
				serviceDef := module.serviceDef(serviceId)
				moduleServiceDefs.add(serviceDef)
				allServiceDefs.add(serviceDef)
				
				if (serviceIdToModule.containsKey(serviceId)) {
					existing := serviceIdToModule[serviceId]
					throw IocErr(IocMessages.serviceIdConflict(serviceId, existing.serviceDef(serviceId), serviceDef))
				}

				serviceIdToModule[serviceId] = module

				// The service is defined but will not have gone further than that.
//				tracker.define(serviceDef, Status.DEFINED)
			}
			
			modules.add(module)
		}
		
		builtinServices["registry"] = this
		registryShutdownHub = RegistryShutdownHubImpl()
		builtinServices["registryShutdownHub"] = registryShutdownHub

//        addBuiltin(SERVICE_ACTIVITY_SCOREBOARD_SERVICE_ID, ServiceActivityScoreboard#, tracker)

		// TODO:
//        validateContributeDefs(moduleDefs);
	}
	
	// ---- Registry Methods ----------------------------------------------------------------------
	
	override This startup() {
		// TODO: do earger loading
		return this
	}

	override This shutdown() {
		registryShutdownHub.fireRegistryDidShutdown()
		
		// destroy all internal refs
		builtinServices.clear
		allServiceDefs.clear
		modules.clear
		serviceIdToModule.clear
		
		return this
	}

	override Obj serviceById(Str serviceId) {
		OpTracker().track("Locating service by ID '$serviceId'") |tracker| {
			trackServiceById(tracker, serviceId)
		}
	}

	override Obj dependencyByType(Type dependencyType) {
		OpTracker().track("Locating dependency by type '$dependencyType.qname'") |tracker| {
			trackDependencyByType(tracker, dependencyType)
		}
	}

	override Obj autobuild(Type type) {
		log.info("Autobuilding $type.qname")
		return trackAutobuild(OpTracker(), type)
	}

	override Obj injectIntoFields(Obj object) {
		log.info("Injecting dependencies into fields of $object.typeof.qname")
		return trackInjectIntoFields(OpTracker(), object)
	}

	// ---- ObjLocator Methods --------------------------------------------------------------------

	override Obj trackServiceById(OpTracker tracker, Str serviceId) {
		if (builtinServices.containsKey(serviceId))
			return builtinServices[serviceId]

		containingModule := locateModuleForService(serviceId)
        return containingModule.service(tracker, serviceId)
	}
	
	override Obj trackDependencyByType(OpTracker tracker, Type dependencyType) {
        Str[] serviceIds := findServiceIdsForType(dependencyType)

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

	// ---- Private Methods -----------------------------------------------------------------------
	
    private Str[] findServiceIdsForType(Type serviceType) {
        Str[] result := [,]

		modules.each |module| {
			result.addAll(module.findServiceIdsForType(serviceType))
		}

		builtinServices.each |service, serviceId| {
			if (service.typeof.fits(serviceType))
				result.add(serviceId)
		}

        return result;
    }	

	private Module locateModuleForService(Str serviceId) {
		if (!serviceIdToModule.containsKey(serviceId))
            throw UnknownValueErr("Service id '${serviceId}' is not defined by any module.", "Defined service ids", serviceIdToModule.keys)
        return serviceIdToModule[serviceId]
    }
}
