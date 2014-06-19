using concurrent

** It would be nice to hardcode these contributions in RegistryImpl so we can delete this class - but 
** that would require a new ContribitionImpl -> too much work!
internal class IocModule {

	@Contribute { serviceType=DependencyProviders# }
	static Void contributeDependencyProviders(OrderedConfig config, LogProvider logProvider) {
		serviceIdProvider	:= config.autobuild(ServiceIdProvider#)
		autobuildProvider	:= config.autobuild(AutobuildProvider#)
		localRefProvider	:= config.autobuild(LocalRefProvider#)
		localListProvider	:= config.autobuild(LocalListProvider#)
		localMapProvider	:= config.autobuild(LocalMapProvider#)

		config.add(serviceIdProvider)
		config.add(autobuildProvider)
		config.add(localRefProvider)
		config.add(localListProvider)
		config.add(localMapProvider)
		config.add(logProvider)
	}
	
	@Contribute { serviceType=ActorPools# }
	static Void contributeActorPools(MappedConfig config) {
		config[IocConstants.systemActorPool] = ActorPool() { it.name = IocConstants.systemActorPool } 
	}
	
	@Contribute { serviceType=RegistryStartup# }
	static Void contributeRegistryStartup(OrderedConfig config, Registry regsitry, RegistryMeta registryMeta) {
		config.addOrdered("afIoc.showServices") |->| {
			((RegistryImpl) regsitry).showServices.val = true
			// TODO: afBedSheet-1.3.10 remove when live
			if (registryMeta.options.get("suppressStartupServiceList") == true)
				((RegistryImpl) regsitry).showServices.val = false	
		}

		config.addOrdered("afIoc.showBanner") |->| {
			((RegistryImpl) regsitry).showBanner.val = true
			// TODO: afBedSheet-1.3.10 remove when live
			if (registryMeta.options.get("suppressStartupBanner") == true)
				((RegistryImpl) regsitry).showServices.val = false				
		}
	}

	@Contribute { serviceType=RegistryShutdown# }
	static Void contributeIocShutdownPlaceholder(OrderedConfig config, Registry regsitry) {
		config.addPlaceholder("afIoc.shutdown")
		
		config.addOrdered("afIoc.sayGoodbye") |->| {
			((RegistryImpl) regsitry).sayGoodbye.val = true
		}
	}
}
