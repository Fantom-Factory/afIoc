
internal class IocModule {
	
	static Void bind(ServiceBinder binder) {
		
		// RegistryStartup needs to be perThread so other perThread listeners can be injected into it 
		binder.bindImpl(RegistryStartup#).withScope(ServiceScope.perThread)
		
		// new up Built-In services ourselves to cut down on debug noise
//		binder.bindImpl(RegistryShutdownHub#).withScope(ServiceScope.perApplication)

		// TODO: new up - see above
//		binder.bindImpl(DependencyProviderSource#)
	}
		
}
