using concurrent
using afPlastic

internal const class IocModule {

	static Void defineServices(ServiceDefinitions defs) {
		defs.add(Registry#) 
		defs.add(RegistryMeta#) 
		defs.add(RegistryStartup#).withScope(ServiceScope.perThread)	// for non-const listeners 
		defs.add(RegistryShutdown#)
		
		defs.add(DependencyProviders#)
		defs.add(LogProvider#)
		defs.add(PlasticCompiler#)
		defs.add(ServiceProxyBuilder#)
		defs.add(ThreadLocalManager#) 
	}
	
	@Build
	static ActorPools buildActorPools(Str:ActorPool actorPools, RegistryMeta regMeta) {
		actorPools[IocConstants.systemActorPool] = regMeta[IocConstants.systemActorPool]
		return ActorPoolsImpl(actorPools)
	}
	
	@Contribute { serviceType=DependencyProviders# }
	static Void contributeDependencyProviders(Configuration config, LogProvider logProvider) {
		config["afIoc.autobuildProvider"]	= config.autobuild(AutobuildProvider#)
		config["afIoc.localProvider"]		= config.autobuild(LocalProvider#)
		config["afIoc.logProvider"]			= logProvider
		config["afIoc.configProvider"]		= config.autobuild(ConfigProvider#)
		config["afIoc.ctorItBlockProvider"]	= config.autobuild(CtorItBlockProvider#)
		config["afIoc.serviceProvider"]		= config.autobuild(ServiceProvider#)
	}	

	@Contribute { serviceType=RegistryStartup# }
	static Void contributeRegistryStartup(Configuration config) {
		reg := (RegistryImpl) config.registry

		config["afIoc.logServices"] = |->| {
			reg.logServices.val = true
		}
		config["afIoc.logBanner"] = |->| {
			reg.logBanner.val = true
		}
	}

	@Contribute { serviceType=RegistryShutdown# }
	static Void contributeIocShutdownPlaceholder(Configuration config) {
		reg := (RegistryImpl) config.registry

		config.addPlaceholder("afIoc.shutdown")
		config["afIoc.sayGoodbye"] = |->| {
			reg.sayGoodbye.val = true
		}
	}
}
