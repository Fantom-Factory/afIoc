
class RegistryImpl : Registry, RegistryShutdownHub {
	
	private OperationTracker 		operationTracker
	private RegistryShutdownHubImpl registryShutdownHub
	private ServiceDef[]			allServiceDefs		:= [,]
	private Module:ServiceDef[]		moduleToServiceDefs	:= [:]

	
	new make(ModuleDef[] moduleDefs) {
		
		operationTracker = OperationTrackerImpl(Log.get(Registry#.name)) 
		
		hubLogger := loggerForBuiltinService(REGISTRY_SHUTDOWN_HUB_SERVICE_ID);
		registryShutdownHub = RegistryShutdownHubImpl(hubLogger)
		
		lifecycles.add("singleton", SingletonServiceLifecycle())
		
		moduleDefs.each |def| {   
			logger := Log.get(def.loggerName)
			
			module := ModuleImpl(this, tracker, def, logger)
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
				tracker.define(serviceDef, Status.DEFINED)
			}
			
			moduleToServiceDefs[module] = moduleServiceDefs
		}
		
        addBuiltin(SERVICE_ACTIVITY_SCOREBOARD_SERVICE_ID, ServiceActivityScoreboard#, tracker)
        addBuiltin(REGISTRY_SHUTDOWN_HUB_SERVICE_ID, RegistryShutdownHub#, registryShutdownHub)

		// TODO:
//        validateContributeDefs(moduleDefs);

		// TODO:
//        SerializationSupport.setProvider(this);		
	}
	
}
