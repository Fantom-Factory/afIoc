using concurrent::AtomicRef
using afConcurrent::LocalMap
using afConcurrent::LocalRef

**
** Wraps an IoC `Registry` instance as Fantom service.
** 
** The Service of Services!
** 
const class IocService : Service {
	private static const Log 	log 		:= Utils.getLog(IocService#)
	private const LocalRef	 	builderRef	:= LocalRef("builder") |->Obj?| { RegistryBuilder() }
	private const LocalRef	 	startErrRef	:= LocalRef("startErr")
	private const AtomicRef		registryRef	:= AtomicRef()

	private RegistryBuilder builder {
		get { builderRef.val }
		set { builderRef.val = it }
	}
	
	Registry? registry {
		// ensure the registry is shared amongst all threads 
		get { 
			// rethrow any errs that occurred on startup 
			// see http://fantom.org/sidewalk/topic/2133
			if (startErrRef.isMapped)
				throw startErrRef.val
			return registryRef.val 
		}
		private set { registryRef.val = it }
	}

	

	// ---- Public Builder Methods ---------------------------------------------------------------- 

	new make(Type[] moduleTypes := [,]) {
		startErrRef.cleanUp
		builderRef.cleanUp
		builder.addModules(moduleTypes)
	}

	** Convenience for `RegistryBuilder.addModules`
	This addModules(Type[] moduleTypes) {
		checkServiceNotStarted
		builder.addModules(moduleTypes)
		return this
	}
	
	** Convenience for `RegistryBuilder.addModulesFromPod`
	This addModulesFromPod(Pod pod, Bool addDependencies := true) {
		checkServiceNotStarted
		builder.addModulesFromPod(pod, addDependencies)
		return this
	}

	** Convenience for `RegistryBuilder.addModulesFromIndexProps`
	This addModulesFromIndexProps() {
		checkServiceNotStarted
		builder.addModulesFromIndexProps
		return this
	}

	// ---- Service Lifecycle Methods ------------------------------------------------------------- 

	** Builds and starts up the registry.
	** See `RegistryBuilder.build`.
	** See `Registry.startup`.
	override Void onStart() {
		checkServiceNotStarted
		log.info("Starting IOC...");
	
		try {
			startErrRef.cleanUp
			
			registry = builder.build
			
			registry.startup
			
		} catch (Err e) {
			log.err("Err starting IOC", e)
			
			// keep the err so we can rethrow later (as 'Service.start()' swallows it)
			// see http://fantom.org/sidewalk/topic/2133
			startErrRef.val = e
			
			// re throw so Fantom doesn't start the service (since Fantom 1.0.65)
			// see http://fantom.org/sidewalk/topic/2133
			throw e

		} finally {
			builderRef.cleanUp
		}
	}

	** Shuts down the registry.
	** See `Registry.shutdown`.
	override Void onStop() {
		if (registry == null) {
			log.info("Registry already stopped.")
			return
		}
		log.info("Stopping IOC...");
		registry.shutdown
		registry = null
	}



	// ---- Registry Methods ----------------------------------------------------------------------
	
	** Convenience for `Registry#serviceById`
	Obj serviceById(Str serviceId, Bool checked := true) {
		checkServiceStarted
		return registry.serviceById(serviceId, checked)
	}
	
	** Convenience for `Registry#dependencyByType`
	Obj dependencyByType(Type serviceType, Bool checked := true) {
		checkServiceStarted
		return registry.dependencyByType(serviceType, checked)
	}

	** Convenience for `Registry#autobuild`
	Obj autobuild(Type type, Obj?[]? ctorArgs := null, [Field:Obj?]? fieldVals := null) {
		checkServiceStarted
		return registry.autobuild(type, ctorArgs, fieldVals)
	}
	
	** Convenience for `Registry#createProxy`
	Obj createProxy(Type mixinType, Type implType, Obj?[]? ctorArgs := null, [Field:Obj?]? fieldVals := null) {
		checkServiceStarted
		return registry.createProxy(mixinType, implType, ctorArgs, fieldVals)
	}
	
	** Convenience for `Registry#injectIntoFields`
	Obj injectIntoFields(Obj instance) {
		checkServiceStarted
		return registry.injectIntoFields(instance)
	}
	
	** Convenience for `Registry#callMethod`
	Obj? callMethod(Method method, Obj? instance, Obj?[]? providedMethodArgs := null) {
		checkServiceStarted
		return registry.callMethod(method, instance, providedMethodArgs)
	}

	** Convenience for `Registry#serviceDefinitions`
	Str:ServiceDefinition serviceDefinitions() {
		checkServiceStarted
		return registry.serviceDefinitions		
	}

	// ---- Private Methods -----------------------------------------------------------------------

	private Void checkServiceStarted() {
		if (registry == null)
			throw IocErr(IocMessages.serviceNotStarted)
	}

	private Void checkServiceNotStarted() {
		if (registry != null)
			throw IocErr(IocMessages.serviceStarted)
	}	
}
