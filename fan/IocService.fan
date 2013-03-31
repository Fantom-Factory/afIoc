
const class IocService : Service {
	private static const Log 		log 		:= Log.get(IocService#.name)
	private const LocalStash 		stash		:= LocalStash(typeof)
	private const ConcurrentState	conState	:= ConcurrentState(IocServiceState#)
	private const Type[]			moduleTypes

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
		get { conState.getState |IocServiceState state->Obj| { return state.registry } }
		private set { }
	}
	
	// ---- Public Builder Methods ---------------------------------------------------------------- 

	new make(Type[] moduleTypes := [,]) {
		this.moduleTypes 	= moduleTypes
		this.indexProps		= false
		this.dependencies	= false
	}
	
	This loadModulesFromDependencies(Pod dependenciesOf) {
		dependencies = true
		dependencyPod = dependenciesOf
		return this
	}

	This loadModulesFromIndexProperties() {
		indexProps = true
		return this
	}

	// ---- Service Lifecycle Methods ------------------------------------------------------------- 

	override Void onStart() {
		log.info("Starting IOC...");
	
		try {
			regBuilder := RegistryBuilder()
			
			if (indexProps)
				regBuilder.addModulesFromIndexProperties
			
			if (dependencies)
				regBuilder.addModulesFromDependencies(dependencyPod)
			
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
		log.info("Stopping IOC...");
		registry.shutdown
	}
	
	// ---- Registry Methods ----------------------------------------------------------------------
	
	** Convenience for `Registry.serviceById`
	Obj serviceById(Str serviceId) {
		checkRegistry
		return registry.serviceById(serviceId)
	}
	
	** Convenience for `Registry.dependencyByType`
	Obj dependencyByType(Type serviceType) {
		checkRegistry
		return registry.dependencyByType(serviceType)
	}

	** Convenience for `Registry.autobuild`
	Obj autobuild(Type type) {
		checkRegistry
		return registry.autobuild(type)
	}
	
	** Convenience for `Registry.injectIntoFields`
	Obj injectIntoFields(Obj service) {
		checkRegistry
		return registry.injectIntoFields(service)
	}	

	private Void checkRegistry() {
		if (registry == null)
			throw IocErr(IocMessages.registryNotBuild)
	}
}

internal class IocServiceState {
	Registry? registry
}
