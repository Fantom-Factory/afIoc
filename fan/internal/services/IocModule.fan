using concurrent

** It would be nice to hardcode this contribution in RegistryImpl so we can delete this class - but 
** that would require a new ContribitionImpl -> too much work!
internal class IocModule {

	@Contribute { serviceType=DependencyProviderSource# }
	static Void contributeDependencyProviderSource(OrderedConfig config, LogProvider logProvider) {
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
		config["afIoc.system"] = ActorPool()
	}
}
