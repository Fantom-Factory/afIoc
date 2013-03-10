
//class RegistryImpl : Registry, RegistryShutdownHub {
internal class RegistryImpl : Registry, ObjLocator {
	
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
		
		registryShutdownHub = RegistryShutdownHubImpl()
		builtinServices["registryShutdownHub"] = registryShutdownHub

//        addBuiltin(SERVICE_ACTIVITY_SCOREBOARD_SERVICE_ID, ServiceActivityScoreboard#, tracker)

		// TODO:
//        validateContributeDefs(moduleDefs);
	}
	
	override This startup() {
		// TODO: do earger loading
		return this
	}
	
	override This shutdown() {
		registryShutdownHub.fireRegistryDidShutdown()
		return this
	}

	override Obj serviceById(Str serviceId) {
		if (builtinServices.containsKey(serviceId))
			return builtinServices[serviceId]

		containingModule := locateModuleForService(serviceId)
        return containingModule.service(serviceId)
	}
	
	override Obj serviceByType(Type serviceType) {
        Str[] serviceIds := findServiceIdsForType(serviceType)

		if (serviceIds.isEmpty)
			throw IocErr(IocMessages.noServiceMatchesType(serviceType))
		if (serviceIds.size > 1)
			throw IocErr(IocMessages.manyServiceMatches(serviceType, serviceIds))

		serviceId := serviceIds.get(0)
        return serviceById(serviceId)
	}

	override Obj autobuild(Type type, Str description := "Building '$type.qname'") {
		return InternalUtils.autobuild(this, type)
	}
	
	override Obj injectIntoFields(Obj object) {
		return InternalUtils.injectIntoFields(this, object)
	}
	
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
