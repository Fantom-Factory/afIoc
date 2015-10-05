using concurrent::AtomicBool

** (Service) - 
@Js
const mixin Scope {
	
	abstract Str 		id()
	abstract Scope?		parent()
	abstract Registry	registry()
	
	abstract Obj build(Type type, Obj?[]? ctorArgs := null, [Field:Obj?]? fieldVals := null)
	
	abstract Obj inject(Obj obj)
	
	abstract Obj? callMethod(Method method, Obj? instance, Obj?[]? args := null)

	abstract Obj? callFunc(Func func, Obj?[]? args := null)

	** Resolves a serivce by its ID.
	abstract Obj? serviceById(Str serviceId, Bool checked := true)

	** Resolves a serivce by its Type.
	abstract Obj? serviceByType(Type serviceType, Bool checked := true)
	
	abstract Void createChildScope(Str scopeId, |Scope| f)
		

	abstract This jailBreak()
	abstract Void destroy()
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
