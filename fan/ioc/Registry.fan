
** (Service) - The registry of IoC services.
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
	** 
	** The other parameters (if provided) may be passed to the autobuild ctor. Handy when you wish the ctor to take a 
	** mixture of objects and services. e.g. for a `fwt::Command`:
	** 
	** pre>
	**   registry.autobuild(MySaveCommand#, [entityToSave]).invoke(null)
	**   ..
	**   class MySaveCommand {
	**     @Inject
	**     private EntityDao entityDao
	**     
	**     private Entity entity
	** 
	**     new make(Entity entity, OtherService service, |This| injectInto) {
	**       injectInto(this)       // ioc to inject all fields
	**       service.doSomething    // this service is only used here, so doesn't need to be a field 
	**       entityDao.save(entity) // use the field service and passed in entity 
	**     }
	**   }
	** <pre
	** 
	** Note: the passed in parameters **must** be first in the ctor parameter list.
	** 
	** Impl note: A list is used rather than splats so 'nulls' can be passed in. 
    abstract Obj autobuild(Type type, Obj?[] ctorArgs := Obj#.emptyList)

	** A companion method to 'autobuild'. Creates an instance of the given mixin, which creates the real instance 
	** whenever a mixin method is invoked.
	** 
	** @since 1.5.0
	abstract Obj createProxy(Type mixinType, Type implType, Obj?[] ctorArgs := Obj#.emptyList)

	** Injects services and dependencies into fields (of all visibilities) marked with '@Inject'.
	** 
	** Returns the object passed in for method chaining.
	** 
	** *Note usage of this method is discouraged, it is far better practice for the creator to call 'autobuild' 
	** instead.*  
	abstract Obj injectIntoFields(Obj service)

	** Calls the method, dependency injecting the parameters. 'instance' can be 'null' if calling a static method. 
	** 
	** The optional 'providedMethodArgs' are used as method arguments. Any args not provided are dependency injected.
	** 
	** @since 1.5.0
	abstract Obj? callMethod(Method method, Obj? instance, Obj?[] providedMethodArgs := Obj#.emptyList)
}
