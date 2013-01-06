
//class RegistryImpl : Registry, RegistryShutdownHub {
internal class RegistryImpl : Registry, ObjLocator {
	
//	private OperationTracker 		operationTracker
//	private RegistryShutdownHubImpl registryShutdownHub

	private Str:Obj					builtinServices 	:= Str:Obj[:] 		{ caseInsensitive = true }
	private Str:Type				builtinTypes 		:= Str:Type[:]		{ caseInsensitive = true }
	
	private ServiceDef[]			allServiceDefs		:= [,]
//	private Module:ServiceDef[]		moduleToServiceDefs	:= [:]
	private Module[]				modules				:= [,]
	private Str:Module				serviceIdToModule 	:= Str:Module[:]	{ caseInsensitive = true }
	
	new make(ModuleDef[] moduleDefs) {
//		operationTracker = OperationTrackerImpl(Log.get(Registry#.name)) 
		
//		hubLogger := loggerForBuiltinService(REGISTRY_SHUTDOWN_HUB_SERVICE_ID);
//		registryShutdownHub = RegistryShutdownHubImpl(hubLogger)
		
//		lifecycles.add("singleton", SingletonServiceLifecycle())
		
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
			
//			moduleToServiceDefs[module] = moduleServiceDefs
			modules.add(module)
		}
		
//        addBuiltin(SERVICE_ACTIVITY_SCOREBOARD_SERVICE_ID, ServiceActivityScoreboard#, tracker)
//        addBuiltin(REGISTRY_SHUTDOWN_HUB_SERVICE_ID, RegistryShutdownHub#, registryShutdownHub)

		// TODO:
//        validateContributeDefs(moduleDefs);

		// TODO:
//        SerializationSupport.setProvider(this);		
	}
	
	override This performRegistryStartup() {
		// TODO: do earger loading
		return this
	}
	
	override This shutdown() {
		// TODO: do reg shutdown hub
		return this
	}

	override Obj serviceById(Str serviceId) {
        return serviceByIdAndType(serviceId, null)
	}
	
	override Obj serviceByType(Type serviceType) {
        Str[] serviceIds := findServiceIdsForType(serviceType)

		if (serviceIds.isEmpty)
			throw IocErr(IocMessages.noServiceMatchesType(serviceType))
		if (serviceIds.size > 1)
			throw IocErr(IocMessages.manyServiceMatches(serviceType, serviceIds))

		serviceId := serviceIds.get(0)
        return serviceByIdAndType(serviceId, serviceType)
	}

	override Obj autobuild(Type type, Str description := "Building '$type.qname'") {
		ctor := InternalUtils.findAutobuildConstructor(type)
		obj := ctor.call	// TODO: call with params
		InternalUtils.injectIntoFields(obj, this)
		return obj
	}
		
	private Obj serviceByIdAndType(Str serviceId, Type? serviceType) {
        result := checkForBuiltinService(serviceId, serviceType)
        if (result != null)
            return result

        // Checking serviceId and serviceInterface is overkill; they have been checked and rechecked
        // all the way to here.

        containingModule := locateModuleForService(serviceId)

        return containingModule.service(serviceId)		
	}
	
    private Obj? checkForBuiltinService(Str serviceId, Type? serviceType := null) {
        Obj? service := builtinServices.get(serviceId)

        if (service == null)
            return null

		if (serviceType != null)
			if (!service.typeof.fits(serviceType))
	            throw IocErr(IocMessages.serviceWrongType(serviceId, builtinTypes.get(serviceId), serviceType))
		
		return service
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
