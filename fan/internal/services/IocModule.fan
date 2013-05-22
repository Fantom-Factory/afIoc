
** It would be nice to hardcode this contribution in RegistryImpl so we can delete this class - but 
** that would require a new ContribitionImpl; too much work!
internal class IocModule {

	@Contribute
	static Void contributeDependencyProviderSource(OrderedConfig config) {
		serviceIdProvider := config.autobuild(ServiceIdProvider#)
		autobuildProvider := config.autobuild(AutobuildProvider#)

		config.addUnordered(serviceIdProvider)
		config.addUnordered(autobuildProvider)
	}
}
