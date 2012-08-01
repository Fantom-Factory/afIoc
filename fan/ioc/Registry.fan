
mixin Registry : ObjLocator {
	
 	** Invoked to eagerly load services marked with the {@link EagerLoad} annotation, and to execute all contributions
	** to the Startup service.
	abstract Void performRegistryStartup()
	
	** Shuts down a Registry instance. Notifies all listeners that the registry has shutdown. Further method invocations
	** on the Registry are no longer allowed, and the Registry instance should be discarded.
	**
	** See `RegistryShutdownHub`
	abstract Void shutdown()
}
