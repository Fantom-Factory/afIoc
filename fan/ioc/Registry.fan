
** (Service) - The registry of IoC services; this is the main IoC service. 
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

	// The search takes into account inheritance of the service mixin, not the service *implementation*.
	** Locates a dependency of the given type. 
    abstract Obj? dependencyByType(Type dependencyType, Bool checked := true)

	** Autobuilds an instance of the given type, resolving all dependencies: 
	**  - create instance via ctor marked with '@Inject' or the ctor with the *most* parameters
	**  - inject dependencies into fields (of all visibilities) marked with '@Inject'
	**  - call any methods annotated with '@PostInjection'
	** 
	** 'ctorArgs' (if provided) will be passed as arguments to the first parameters in the autobuild ctor. 
	** Handy when you wish the ctor to take a mixture of plain objects and services. e.g. for a `fwt::Command`:
	** 
	** pre>
	**   registry.autobuild(MySaveCommand#, [entityToSave])
	**   ...
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
	** 
	** 'fieldVals' set (and potentially overwrite) the value of any const fields set by an it-block function.
    abstract Obj autobuild(Type type, Obj?[] ctorArgs := Obj#.emptyList, [Field:Obj?]? fieldVals := null)

	** A companion method to 'autobuild'. Creates an instance of the given mixin, which creates the real instance 
	** whenever a mixin method is invoked.
	** 
	** If 'implType' is null then it is assumed to have the same name as the mixin, plus a 'Impl' suffix.
	** @since 1.5.0
	abstract Obj createProxy(Type mixinType, Type? implType := null, Obj?[] ctorArgs := Obj#.emptyList)

	** Injects services and dependencies into fields (of all visibilities) marked with '@Inject'.
	** 
	** Returns the object passed in for method chaining.
	** 
	** *Note usage of this method is discouraged, it is far better practice for the creator to call 'autobuild' 
	** instead.*  
	abstract Obj injectIntoFields(Obj service)

	** Calls the method, dependency injecting the parameters. 'instance' can be 'null' if calling a static method. 
	** 
	** The optional 'providedMethodArgs' are used as method arguments. Any args not provided are dependency injected; 
	** unless they have a default argument, in which case nothing is passed in and the default is used.
	** 
	** @since 1.5.0
	abstract Obj? callMethod(Method method, Obj? instance, Obj?[] providedMethodArgs := Obj#.emptyList)
}
