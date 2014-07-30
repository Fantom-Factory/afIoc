using concurrent

** It would be nice to hardcode these contributions in RegistryImpl so we can delete this class - but 
** that would require a new ContribitionImpl -> too much work!
internal const class IocModule {

	@Contribute { serviceType=ActorPools# }
	static Void contributeActorPools(Configuration config) {
		config[IocConstants.systemActorPool] = ActorPool() { it.name = IocConstants.systemActorPool } 
	}

	@Contribute { serviceType=DependencyProviders# }
	static Void contributeDependencyProviders(Configuration config, LogProvider logProvider) {
		config["afIoc.localRefProvider"]	= config.autobuild(LocalRefProvider#)
		config["afIoc.localListProvider"]	= config.autobuild(LocalListProvider#)
		config["afIoc.localMapProvider"]	= config.autobuild(LocalMapProvider#)
		config["afIoc.logProvider"]			= logProvider
	}	
	
	@Contribute { serviceType=RegistryStartup# }
	static Void contributeRegistryStartup(Configuration config, RegistryMeta registryMeta) {
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
