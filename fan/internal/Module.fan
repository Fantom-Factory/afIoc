
internal class Module {
	
	private RegistryImpl	 		registry;
	private ServiceActivityTracker	tracker;
	private ModuleDef 				moduleDef
	private Log 					logger
	private Str:ServiceDef			serviceDefs := [:] { caseInsensitive = true }
	private Str:Obj					services 	:= [:] { caseInsensitive = true }
	private Obj?					moduleInstance	// Lazily instantiated
	
	// Set to true when invoking the module constructor. Used to
	// detect endless loops caused by irresponsible dependencies in
	// the constructor.
	private Bool					insideConstructor
	
	new make(RegistryImpl registry, ServiceActivityTracker tracker, ModuleDef moduleDef, Log logger) {
		this.registry 		= registry
		this.tracker 		= tracker
		this.moduleDef 		= moduleDef
		this.logger 		= logger
		this.serviceDefs	= moduleDef.serviceDefs.dup
	}

	
	ServiceDef serviceDef(Str serviceId) {
		serviceDefs[serviceId]
	}

	Obj serviceById(Str serviceId) {
		services.getOrAdd(serviceId) {
			def := serviceDef(serviceId)
			create(def)
		}
	}

//	override Str[] findServiceIdsForType(Type serviceType) {
//		serviceDefs.findAll |def| {
//			def.serviceType.fits(serviceType)
//		}.vals.map |def->Str| { def.serviceId  }
//	}
//	
//	override Void collectEagerLoadServices(EagerLoadServiceProxy[] proxies) {
//		work := |->| {
//			serviceDefs.vals.each |def| {
//				if (def.isEagerLoad)
//					findOrCreate(def, proxies)
//			}
//		}
//
//		registry.run("Eager loading services", work)
//	}

//	Str loggerName() {
//		moduleDef.loggerName
//	}
	
//	Obj moduleBuilder() {
//		if (moduleInstance == null)
//			moduleInstance = registry.invoke("Constructing module class ${moduleDef.moduleType.name}", |->Obj| { instantiateModuleInstance })
//		return moduleInstance
//	}
	
	** Creates the service and updates the cache of created services.
	Obj create(ServiceDef def) {
		serviceId 		:= def.serviceId
		serviceType		:= def.serviceType
		logger 			:= Log.get("${moduleDef.loggerName}.${serviceId}")
		description 	:= "Creating " + (serviceType.isMixin() ? "proxy for" : "non-proxied instance of") + " service ${serviceId}"
		module 			:= this

		logger.debug(description)

		operation := |->Obj| {
			try {
				resources := ServiceResourcesImpl(registry, module, def, logger)

				// Build up a stack of operations that will be needed to realize the service
				// (by the proxy, at a later date).
				creator := def.createServiceCreator(resources)

				if (!serviceType.isMixin) {					
					return creator.createObject
				}

				// TODO:
				throw IocErr("TODO:")
//				creator := OperationTrackingObjectCreator(registry, String.format("Instantiating service %s implementation via %s", serviceId, creator), creator)
//				creator = LifecycleWrappedServiceCreator(lifecycle, resources, creator)
//				creator = RecursiveServiceCreationCheckWrapper(def, creator, logger)
//				creator = OperationTrackingObjectCreator(registry, "Realizing service " + serviceId, creator)
//
//				delegate := JustInTimeObjectCreator(tracker, creator, serviceId)
//				proxy 	:= createProxy(resources, delegate)
//
//				registry.addRegistryShutdownListener(delegate)
//
//				// Occasionally eager load service A may invoke service B from its service builder method; if
//				// service B is eager loaded, we'll hit this method but eagerLoadProxies will be null. That's OK
//				// ... service B is being realized anyway.
//				if (def.isEagerLoad && eagerLoadProxies != null)
//					eagerLoadProxies.add(delegate);
//
//				tracker.setStatus(serviceId, Status.VIRTUAL)
//				return proxy

			} catch (Err ex) {
				throw IocErr(IocMessages.errorBuildingService(serviceId, def, ex), ex)
			}
		}

		return registry.invoke(description, operation);
	}
	
	private Obj instantiateModuleInstance()	{
		moduleType 	:= moduleDef.moduleType
		constructor	:= InternalUtils.findAutobuildConstructor(moduleType)

		if (constructor == null)
			throw IocErr(IocMessages.noPublicConstructors(moduleType))

		if (insideConstructor)
			throw IocErr(IocMessages.recursiveModuleConstructor(moduleType, constructor))
//
//		ObjectLocator locator = new ObjectLocatorImpl(registry, this);
//		Map<Class, Object> resourcesMap = CollectionFactory.newMap();
//
//		resourcesMap.put(Logger.class, logger);
//		resourcesMap.put(ObjectLocator.class, locator);
//		resourcesMap.put(OperationTracker.class, registry);
//
//		InjectionResources resources = new MapInjectionResources(resourcesMap);
//
		Err? fail := null
//
//		try {
//			insideConstructor = true;
//
//			ObjectCreator[] parameterValues = InternalUtils.calculateParameters(locator, resources,
//					constructor.getParameterTypes(), constructor.getGenericParameterTypes(),
//					constructor.getParameterAnnotations(), registry);
//
//			Object[] realized = InternalUtils.realizeObjects(parameterValues);
//
//			Object result = constructor.newInstance(realized);
//
//			InternalUtils.injectIntoFields(result, locator, resources, registry);
//
//			return result;		
//		} finally {
//			insideConstructor = false;
//		}
//
		throw IocErr(IocMessages.instantiateBuilderError(moduleType, fail), fail);
	}	

}
