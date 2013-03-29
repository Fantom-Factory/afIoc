using concurrent

const class IocService : Service {
	private static const Log 	log 	:= Log.get(IocService#.name)
	private const LocalStash 	stash	:= LocalStash(typeof)
	private const Type[]		moduleTypes
	
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

	Registry registry {
		get { stash["registry"] }
		private set { stash["registry"] = it }
	}
	
	// ---- Public Builder Methods ---------------------------------------------------------------- 

	new make(Type[] moduleTypes := [,]) {
		this.moduleTypes = moduleTypes
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
			
			registry = regBuilder.build.startup
			
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
		registry.serviceById(serviceId)
	}
	
	** Convenience for `Registry.dependencyByType`
	Obj dependencyByType(Type serviceType) {
		registry.dependencyByType(serviceType)
	}

	** Convenience for `Registry.autobuild`
	Obj autobuild(Type type) {
		registry.autobuild(type)
	}
	
	** Convenience for `Registry.injectIntoFields`
	Obj injectIntoFields(Obj service) {
		registry.injectIntoFields(service)
	}	
}

internal const class LocalStash {
	private const Str prefix
	
	new make(Type type) {
		this.prefix = type.qname
	}
	
	@Operator
	Obj? get(Str name, |->Obj|? valFunc := null) {
		val := Actor.locals[key(name)]
		if (val == null) {
			if (valFunc != null) {
				val = valFunc.call
				set(name, val)
			}
		}
		return val
	}

	@Operator
	Void set(Str name, Obj? value) {
		Actor.locals[key(name)] = value
	}
	
	private Str key(Str name) {
		return "${prefix}.${name}"
	}
}
