
mixin Registry {
	
 	** Invoked to execute all contributions to the Startup service.
	abstract This startup()
	
	** Shuts down a Registry instance. Notifies all listeners that the registry has shutdown. Further method invocations
	** on the Registry are no longer allowed, and the Registry instance should be discarded.
	**
	** See `RegistryShutdownHub`
	abstract This shutdown()
	
	** Obtains a service via its unique service id. 
    abstract Obj serviceById(Str serviceId)

	** Locates a dependency of the given type. The search takes into account inheritance of the 
	** service mixin, not the service *implementation*.
    abstract Obj dependencyByType(Type dependencyType)

	** Autobuilds a class via a ctor marked with '@Inject', failing that, the ctor with the most 
	** parameters. Services and dependencies will be injected into the ctor parameters, and into 
	** fields (of all visibilities) marked with '@Inject'. 
    abstract Obj autobuild(Type type)

	** Injects services and dependencies into fields (of all visibilities) marked with '@Inject'.
	abstract Obj injectIntoFields(Obj service)	
}
