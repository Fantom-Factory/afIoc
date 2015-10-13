using concurrent::AtomicBool

** (Service) -
** Creates and manages service instances, builds class instances, and performs dependency injection.
** Scopes also create child scopes.
** 
@Js
const mixin Scope {

	** Returns the unique 'id' of this Scope. 
	abstract Str 		id()
	
	** Returns the parent scope.
	abstract Scope?		parent()
	
	** Returns the registry instance this scope belongs to.
	abstract Registry	registry()
	
	** Autobuilds an instance of the given type. Autobuilding performs the following:
	** 
	**  - creates an instance via the ctor marked with '@Inject' or the *best* fitting ctor with the most parameters
	**  - inject dependencies into fields (of all visibilities)
	**  - call any methods annotated with '@PostInjection'
	** 
	** 'ctorArgs' (if provided) will be passed as arguments to the constructor.
	** Constructor parameters should be defined in the following order:
	** 
	**   new make(<config>, <ctorArgs>, <dependencies>, <it-block>) { ... }
	** 
	** Note that 'fieldVals' are set by an it-block function, should the ctor define one.
	abstract Obj build(Type type, Obj?[]? ctorArgs := null, [Field:Obj?]? fieldVals := null)
	
	** Injects services and dependencies into fields of all visibilities.
	** 
	** Returns the object passed in for method chaining.
	abstract Obj inject(Obj obj)
	
	** Calls the given method. Any method arguments not given are resolved as dependencies. 
	** 'instance' may be 'null' if calling a static method.
	** Method parameters should be defined in the following order:
	** 
	**   Void myMethod(<args>, <dependencies>, <default params>) { ... }
	** 
	** Note that nullable and default parameters are treated as optional dependencies.
	** 
	** Returns the result of calling the method.
	abstract Obj? callMethod(Method method, Obj? instance, Obj?[]? args := null)

	** Calls the given func. Any func arguments not given are resolved as dependencies. 
	** Func parameters should be defined in the following order:
	** 
	**   |<args>, <dependencies>, <default params>| { ... }
	** 
	** Note that nullable and default parameters are treated as optional dependencies.
	** 
	** Returns the result of calling the func.
	abstract Obj? callFunc(Func func, Obj?[]? args := null)

	** Resolves a service by its ID. Throws 'IocErr' if the service is not found, unless 'checked' is 'false'.
	abstract Obj? serviceById(Str serviceId, Bool checked := true)

	** Resolves a service by its Type. Throws 'IocErr' if the service is not found, unless 'checked' is 'false'.
	abstract Obj? serviceByType(Type serviceType, Bool checked := true)
	
	** Creates a nested child scope and makes it available to the given function.
	** 
	** pre>
	** syntax: fantom
	** scope.createChildScope("childScopeId") |Scope childScope| {
	**     ...
	** }
	** <pre
	**   
	abstract Void createChildScope(Str scopeId, |Scope| f)

	** Jail breaks a scope so it may be used from outside its closure.
	** 
	** pre>
	** syntax: fantom
	** <pre
	** childScope := (Scope?) null
	** 
	** scope.createChildScope("childScopeId") |childScopeInClosure| {
	**     childScope = childScopeInClosure.jailbreak
	** }
	** 
	** ... use childScope here ...
	** 
	** childScope.destroy
	** <pre
	** 
	** Once jailbroken, you are responsible for calling 'destroy()'.
	abstract This jailBreak()
	
	** Destroys this scope and releases references to any services created. Calls any scope destroy hooks. 
	abstract Void destroy()

	@NoDoc @Deprecated { msg="Use 'build()' instead" }
	Obj autobuild(Type type, Obj?[]? ctorArgs := null, [Field:Obj?]? fieldVals := null) { build(type, ctorArgs, fieldVals) }

	@NoDoc @Deprecated { msg="Use 'inject()' instead" }
	Obj injectIntoFields(Obj obj) { inject(obj) }

	@NoDoc @Deprecated { msg="Use 'serviceByType()' instead" }
	Obj? dependencyByType(Type objType, Bool checked := true) {	serviceByType(objType, checked) }
}


@Js
internal const class ScopeImpl : Scope {
	private  const OneShotLock 		destroyedLock
	private  const ServiceStore		serviceStore
	private  const AtomicBool		jailBroken		:= AtomicBool(false)
	internal const ScopeDefImpl		scopeDef
	override const RegistryImpl		registry
	override const ScopeImpl?		parent
	
	internal new make(RegistryImpl registry, ScopeImpl? parent, ScopeDefImpl scopeDef) {
		this.registry		= registry
		this.scopeDef		= scopeDef
		this.parent			= parent
		this.serviceStore	= ServiceStore(registry, scopeDef.id)
		this.destroyedLock	= OneShotLock(ErrMsgs.scopeDestroyed(id), ScopeDestroyedErr#)
		
		scopeDef.callCreateHooks(parent)
	}

	override Str id() {
		scopeDef.id
	}

	override Obj build(Type type, Obj?[]? ctorArgs := null, [Field:Obj?]? fieldVals := null) {
		destroyedCheck

		registry.serviceInjectStack.push("Building", type.qname)
		try return registry.autoBuilder.autobuild(this, type, ctorArgs, fieldVals, null)
		catch (IocErr ie)	throw ie
		catch (Err err)		throw IocErr(err.msg, err)
		finally registry.serviceInjectStack.pop
	}

	override Obj inject(Obj instance) {
		destroyedCheck

		registry.serviceInjectStack.push("Injecting", instance.typeof.qname)
		try {
			plan := registry.autoBuilder.findFieldVals(this, instance.typeof, instance, null, null)			
			plan.each |val, field| {
				field.set(instance, field.isConst ? val.toImmutable : val)
			}
			return instance
		}
		catch (IocErr ie)	throw ie
		catch (Err err)		throw IocErr(err.msg, err)
		finally registry.serviceInjectStack.pop
	}

	override Obj? callMethod(Method method, Obj? instance, Obj?[]? args := null) {
		destroyedCheck

		registry.serviceInjectStack.push("Calling method", method.qname)
		try {
			methodArgs := registry.autoBuilder.findFuncArgs(this, method.func, args, instance, null)
			return method.callOn(instance, methodArgs)
		}
		catch (IocErr ie)	throw ie
		catch (Err err)		throw IocErr(err.msg, err)
		finally registry.serviceInjectStack.pop
	}

	override Obj? callFunc(Func func, Obj?[]? args := null) {
		destroyedCheck
		if (func.typeof.isGeneric)
			throw ArgErr("Can not call generic functions: ${func.typeof.signature}")

		registry.serviceInjectStack.push("Calling func", func.typeof.signature)
		try {
			funcArgs := registry.autoBuilder.findFuncArgs(this, func, args, null, null)
			return func.callList(funcArgs)
		}
		catch (IocErr ie)	throw ie
		catch (Err err)		throw IocErr(err.msg, err)
		finally registry.serviceInjectStack.pop
	}
	
	override Obj? serviceById(Str serviceId, Bool checked := true) {
		destroyedCheck		
		
		registry.serviceInjectStack.push("Resolving ID", serviceId)
		registry.serviceInjectStack.setServiceId(serviceId)
		try 	return serviceById_(serviceId, Str[,], checked)
		catch	(IocErr ie)	throw ie
		catch	(Err err)	throw IocErr(err.msg, err)
		finally registry.serviceInjectStack.pop
	}

	internal Obj? serviceById_(Str serviceId, Str[] scopes, Bool checked := true) {
		serviceInstance := serviceStore.instanceById(serviceId)
		if (serviceInstance == null)
			return parent?.serviceById_(serviceId, scopes.add(id), checked)
				?: (checked ? throw ServiceNotFoundErr(ErrMsgs.scope_couldNotFindServiceById(serviceId, scopes.dup.add(id).reverse), services(scopes.dup.add(id).reverse)) : null)
		return serviceInstance.getOrBuild(this)
	}

	override Obj? serviceByType(Type serviceType, Bool checked := true) {
		destroyedCheck

		registry.serviceInjectStack.push("Resolving Type", serviceType.qname)
		try		return serviceByType_(serviceType, Str[,], checked)
		catch	(IocErr ie)	throw ie
		catch	(Err err)	throw IocErr(err.msg, err)
		finally registry.serviceInjectStack.pop
	}

	internal Obj? serviceByType_(Type serviceType, Str[] scopes, Bool checked := true) {
		serviceInstance := serviceStore.instanceByType(serviceType)
		if (serviceInstance == null)
			return parent?.serviceByType_(serviceType, scopes.add(id), checked)
				?: (checked ? throw ServiceNotFoundErr(ErrMsgs.scope_couldNotFindServiceByType(serviceType, scopes.dup.add(id).reverse), services(scopes.dup.add(id).reverse)) : null)
		registry.serviceInjectStack.setServiceId(serviceInstance.def.id)
		return serviceInstance.getOrBuild(this)			
	}
	
	override Void createChildScope(Str scopeId, |Scope| f) {
		destroyedCheck

		childScopeDef	:= registry.findScopeDef(scopeId, this)
		childScope 		:= ScopeImpl(registry, this, childScopeDef)
		registry.activeScopeStack.push(childScope)
		try {
			f.call(childScope)
		} finally {
			createChildScopeFinally(childScope)
		}
	}

	// see http://fantom.org/forum/topic/2481
	private Void createChildScopeFinally(ScopeImpl childScope) {
		try		{childScope.destroyInternal}
		finally {registry.activeScopeStack.pop}		
	}

	override This jailBreak() {
		destroyedCheck
		this.jailBroken.val = true
		return this
	}

	override Void destroy() {
		// keeping a thread safe / synchronised list of active children is only achievable using 
		// Actors or a couple of locking flags. Either way, the contention overhead for dealing 
		// with multiple threads (e.g. BedSheet) makes it unrealistic for what little gain it 
		// gives - primarily ensuring child scopes are destroyed before their parents, which is
		// only of concern if someone has destroy hooks on both scopes.
		//
		// An IoC module could easily be created to compensate for this if absolutely needed. 
		if (destroyedLock.lock) return
		
		scopeDef.callDestroyHooks(parent)

		serviceStore.destroy
	}
	
	internal Void destroyInternal() {
		if (!jailBroken.val)
			destroy
	}

	internal Void destroyedCheck() {
		destroyedLock.check

		// just in case someone forgets to destroy a jail broken scope
		// also allows active threaded scopes to check the status of the root scope during registry shutdown
		try	parent?.destroyedCheck
		catch (ScopeDestroyedErr err) {
			destroy
			throw err
		}
	}

	internal ServiceDefImpl? serviceDefById(Str serviceId, Bool checked) {
		instanceById(serviceId, Str[,], checked)?.def
	}

	internal ServiceDefImpl? serviceDefByType(Type serviceType, Bool checked) {
		instanceByType(serviceType, Str[,], checked)?.def
	}

	internal ServiceInstance? instanceById(Str serviceId, Str[] scopes, Bool checked) {
		serviceStore.instanceById(serviceId)
			?: (parent?.instanceById(serviceId, scopes.add(id), checked)
				?: (checked ? throw ServiceNotFoundErr(ErrMsgs.scope_couldNotFindServiceById(serviceId, scopes.dup.add(id).reverse), services(scopes.dup.add(id).reverse)) : null)
			)
	}

	internal ServiceInstance? instanceByType(Type serviceType, Str[] scopes, Bool checked) {
		serviceStore.instanceByType(serviceType)
			?: (parent?.instanceByType(serviceType, scopes.add(id), checked)
				?: (checked ? throw ServiceNotFoundErr(ErrMsgs.scope_couldNotFindServiceByType(serviceType, scopes.dup.add(id).reverse), services(scopes.dup.add(id).reverse)) : null)
			)
	}
	
	private Str[] services(Str[] scopes) {
		scopes.map |scope| { registry.scopeIdLookup[scope].map { "$scope - $it" } }.flatten
	}
	
	override Str toStr() {
		"Scope: $id"
	}
}
