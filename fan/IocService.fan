
** Wraps a `Registry` instance as Fantom service. 
const class IocService : Service {
	private static const Log 		log 		:= Utils.getLog(IocService#)
	private const LocalStash 		stash		:= LocalStash(typeof)
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

	Registry? registry {
		// ensure the registry is shared amongst all threads 
		get { conState.getState |IocServiceState state->Obj?| { return state.registry } }
		private set { reg := it; conState.withState |IocServiceState state| { state.registry = reg} }
	}


	// ---- Public Builder Methods ---------------------------------------------------------------- 

	new make(Type[] moduleTypes := [,]) {
		this.moduleTypes 	= moduleTypes
		this.indexProps		= false
		this.dependencies	= false
	}
	
	This addModulesFromDependencies(Pod dependenciesOf) {
		checkServiceNotStarted
		dependencies = true
		dependencyPod = dependenciesOf
		return this
	}

	This addModulesFromIndexProperties() {
		checkServiceNotStarted
		indexProps = true
		return this
	}

	This addModules(Type[] moduleTypes) {
		checkServiceNotStarted
		this.moduleTypes = this.moduleTypes.addAll(moduleTypes)
		return this
	}


	// ---- Service Lifecycle Methods ------------------------------------------------------------- 

	override Void onStart() {
		checkServiceNotStarted
		log.info("Starting IOC...");
	
		try {
			regBuilder := RegistryBuilder()
			
			if (indexProps)
				regBuilder.addModulesFromIndexProperties
			
			if (dependencies)
				regBuilder.addModulesFromDependencies(dependencyPod, true)
			
			regBuilder.addModules(moduleTypes)
			
			registry := regBuilder.build.startup
			
			conState.withState |IocServiceState state| {
				state.registry = registry
			}
			
		} catch (Err e) {
			log.err("Err starting IOC", e)
			throw e
		}
	}

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
	
	** Convenience for `Registry.serviceById`
	Obj serviceById(Str serviceId) {
		checkServiceStarted
		return registry.serviceById(serviceId)
	}
	
	** Convenience for `Registry.dependencyByType`
	Obj dependencyByType(Type serviceType) {
		checkServiceStarted
		return registry.dependencyByType(serviceType)
	}

	** Convenience for `Registry.autobuild`
	Obj autobuild(Type type) {
		checkServiceStarted
		return registry.autobuild(type)
	}
	
	** Convenience for `Registry.injectIntoFields`
	Obj injectIntoFields(Obj service) {
		checkServiceStarted
		return registry.injectIntoFields(service)
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
