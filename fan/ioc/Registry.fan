
** The registry of IoC services.
const mixin Registry {
	
 	** Invoke to execute all contributions to the `RegistryStartup` service.
	abstract This startup()
	
	** Shuts down the Registry. Notifies all listeners that the registry has shutdown. Further 
	** method invocations on the Registry are no longer allowed, and the Registry instance 
	** should be discarded.
	**
	** See `RegistryShutdownHub`
	abstract This shutdown()
	
	** Obtains a service via its unique service id. 
    abstract Obj serviceById(Str serviceId)

	** Locates a dependency of the given type. The search takes into account inheritance of the 
	** service mixin, not the service *implementation*.
    abstract Obj dependencyByType(Type dependencyType)

	** Autobuilds an instance of the given type, resolving all dependencies: 
	**  - create instance via ctor marked with '@Inject' or the ctor with the *most* parameters
	**  - inject dependencies into fields (of all visibilities) marked with '@Inject'
	**  - call any methods annotated with '@PostInjection'
    abstract Obj autobuild(Type type)

	** Injects services and dependencies into fields (of all visibilities) marked with '@Inject'.
	** 
	** Returns the object passed in for method chaining.
	abstract Obj injectIntoFields(Obj service)	
}
