
internal class IocModule {

	// TODO: move these out & delete IocModule
	@Contribute
	static Void contributeDependencyProviderSource(OrderedConfig config) {
		serviceIdProvider := config.autobuild(ServiceIdProvider#)
		autobuildProvider := config.autobuild(AutobuildProvider#)

		config.addUnordered(serviceIdProvider)
		config.addUnordered(autobuildProvider)
	}
}
