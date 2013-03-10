
mixin Registry : ObjLocator {
	
 	** Invoked to eagerly load services and execute all contributions to the Startup service.
	abstract This startup()
	
	** Shuts down a Registry instance. Notifies all listeners that the registry has shutdown. Further method invocations
	** on the Registry are no longer allowed, and the Registry instance should be discarded.
	**
	** See `RegistryShutdownHub`
	abstract This shutdown()
}
