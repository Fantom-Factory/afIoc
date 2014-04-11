
** It would be nice to hardcode this contribution in RegistryImpl so we can delete this class - but 
** that would require a new ContribitionImpl -> too much work!
internal class IocModule {

	@Contribute { serviceType=DependencyProviderSource# }
	static Void contributeDependencyProviderSource(OrderedConfig config, LogProvider logProvider) {
		serviceIdProvider	:= config.autobuild(ServiceIdProvider#)
		autobuildProvider	:= config.autobuild(AutobuildProvider#)
		threadStashProvider := config.autobuild(ThreadStashProvider#)

		config.add(serviceIdProvider)
		config.add(autobuildProvider)
		config.add(threadStashProvider)
		config.add(logProvider)
	}
}
