
**
** Wraps an afIoc `Registry` instance as Fantom service.
** 
** A Service for all Services!
** 
const class IocService : Service {
	private static const Log 		log 		:= Utils.getLog(IocService#)
	private const ThreadStash 		stash		:= ThreadStash(IocService#.name)
	private const ConcurrentState	conState	:= ConcurrentState(IocServiceState#)

	private Type[] moduleTypes {
		get { stash["moduleTypes"] }
		set { stash["moduleTypes"] = it }
	}

	private Bool dependencies {
		get { stash["dependencies"] }
		set { stash["dependencies"] = it }
	}

	private Pod dependencyPod {
		get { stash["dependencyPod"] }
		set { stash["dependencyPod"] = it }
	}

	private Bool indexProps {
		get { stash["indexProps"] }
		set { stash["indexProps"] = it }
	}

	private Err? startErr {
		get { stash["startErr"] }
		set { stash["startErr"] = it }
	}

	Registry? registry {
		// ensure the registry is shared amongst all threads 
		get { 
			// rethrow any errs that occurred on startup 
			// see http://fantom.org/sidewalk/topic/2133
			if (startErr != null)
				throw startErr
			return conState.getState |IocServiceState state->Obj?| { return state.registry } 
		}
		private set { reg := it; conState.withState |IocServiceState state| { state.registry = reg} }
	}

	

	// ---- Public Builder Methods ---------------------------------------------------------------- 

	new make(Type[] moduleTypes := [,]) {
		this.moduleTypes 	= moduleTypes
		this.indexProps		= false
		this.dependencies	= false
	}

	** Convenience for `RegistryBuilder.addModules`
	This addModules(Type[] moduleTypes) {
		checkServiceNotStarted
		this.moduleTypes = this.moduleTypes.addAll(moduleTypes)
		return this
	}
	
	** Convenience for `RegistryBuilder.addModulesFromPod`
	This addModulesFromPod(Pod pod) {
		checkServiceNotStarted
		dependencies = true
		dependencyPod = pod
		return this
	}

	** Convenience for `RegistryBuilder.addModulesFromIndexProperties`
	This addModulesFromIndexProperties() {
		checkServiceNotStarted
		indexProps = true
		return this
	}

	@NoDoc @Deprecated	// for afGenesis
	This addModulesFromDependencies(Pod dependenciesOf) {
		addModulesFromPod(dependenciesOf)
	}

	

	// ---- Service Lifecycle Methods ------------------------------------------------------------- 

	** Builds and starts up the registry.
	** See `RegistryBuilder.build`.
	** See `Registry.startup`.
	override Void onStart() {
		checkServiceNotStarted
		log.info("Starting IOC...");
	
		try {
			regBuilder := RegistryBuilder()
			
			if (indexProps)
				regBuilder.addModulesFromIndexProperties
			
			if (dependencies)
				regBuilder.addModulesFromPod(dependencyPod, true)
			
			regBuilder.addModules(moduleTypes)
			
			registry := regBuilder.build
			
			// assign registry now, so it may be looked up (via this service) during startup
			conState.withState |IocServiceState state| {
				state.registry = registry
			}

			registry.startup
			
		} catch (Err e) {
			log.err("Err starting IOC", e)
			
			// keep the err so we can rethrow later (as 'Service.start()' swallows it)
			// see http://fantom.org/sidewalk/topic/2133
			startErr = e
			
			// re throw so Fantom doesn't start the service (since Fantom 1.0.65)
			// see http://fantom.org/sidewalk/topic/2133
			throw e
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
	Obj serviceById(Str serviceId) {
		checkServiceStarted
		return registry.serviceById(serviceId)
	}
	
	** Convenience for `Registry#dependencyByType`
	Obj dependencyByType(Type serviceType) {
		checkServiceStarted
		return registry.dependencyByType(serviceType)
	}

	** Convenience for `Registry#autobuild`
	Obj autobuild(Type type, Obj?[] ctorArgs := Obj#.emptyList, [Field:Obj?]? fieldVals := null) {
		checkServiceStarted
		return registry.autobuild(type, ctorArgs, fieldVals)
	}
	
	** Convenience for `Registry#createProxy`
	Obj createProxy(Type mixinType, Type implType, Obj?[] ctorArgs := Obj#.emptyList, [Field:Obj?]? fieldVals := null) {
		checkServiceStarted
		return registry.createProxy(mixinType, implType, ctorArgs, fieldVals)
	}
	
	** Convenience for `Registry#injectIntoFields`
	Obj injectIntoFields(Obj service) {
		checkServiceStarted
		return registry.injectIntoFields(service)
	}
	
	** Convenience for `Registry#callMethod`
	Obj? callMethod(Method method, Obj? instance, Obj?[] providedMethodArgs := Obj#.emptyList) {
		checkServiceStarted
		return registry.callMethod(method, instance, providedMethodArgs)		
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

internal class IocServiceState {
	Registry? registry
}
