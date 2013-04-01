
internal class IocModule {
	
	static Void bind(ServiceBinder binder) {
		
		// RegistryStartup needs to be perThread so other perThread listeners can be injected into it 
		binder.bindImpl(RegistryStartup#).withScope(ServiceScope.perThread)
		
		binder.bindImpl(RegistryShutdownHub#).withScope(ServiceScope.perApplication)
	}
		
}
