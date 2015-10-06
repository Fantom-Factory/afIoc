using concurrent::AtomicBool
using concurrent::AtomicRef
using concurrent::Actor

@Js
internal const class ServiceStore {
	
	private const RegistryImpl				registry
	private const Str						scopeId
	private const ScopeDef					scopeDef
	private const Str:ServiceInstance		idInstances
	private const Type:Str[]				typeLookup
			const Str[]						serviceIds

	internal new make(RegistryImpl registry, Str scopeId) {
		this.registry	= registry
		this.scopeId	= scopeId
		this.scopeDef	= registry.scopeDefs_.find { it.matchesId(scopeId) }

		idInstances 	:= Str:ServiceInstance[:] { it.caseInsensitive = true }
		registry.scopeIdLookup[scopeId].each |Str serviceId| {
			serviceDef	:= registry.serviceDefs_[serviceId]
			instance	:= ServiceInstance(serviceDef)
			serviceDef.serviceIds.each |id| {
				idInstances[id] = instance
			}
		}
		
		this.typeLookup		= registry.scopeTypeLookup[scopeId]
		this.idInstances	= idInstances
		this.serviceIds		= idInstances.keys
	}

	ServiceInstance? instanceById(Str id) {
		idInstances[id]
	}
	
	ServiceInstance? instanceByType(Type type) {
		serviceType := type.toNonNullable
		serviceIds	:= typeLookup[serviceType] ?: Str#.emptyList
		if (serviceIds.isEmpty)
			return null
		if (serviceIds.size == 1)
			return idInstances[serviceIds.first]
		throw IocErr(ErrMsgs.serviceStore_multipleServicesMatchType(serviceType, serviceIds))
	}
	
	Void destroy() {
		idInstances.each {
			it.destroy
		}
	}
}

@Js
internal const class ServiceInstance {
	const ServiceDefImpl 	def
	const AtomicRef			instance
	const AtomicBool		building
	const AtomicRef			buildErr
	
	new make(ServiceDefImpl serviceDef) {
		this.def 		= serviceDef
		this.instance	= AtomicRef(null)
		this.building	= AtomicBool(false)
		this.buildErr	= AtomicRef(null)
	}
	
	Obj getOrBuild(Scope currentScope) {
		unsafe := (Unsafe?) instance.val
		if (unsafe != null)
			return unsafe.val
		
		if (building.compareAndSet(false, true)) {
			
			try {
				buildErr.val = null
				instance.val = Unsafe(build(currentScope))

			} catch (Err err) {
				buildErr.val = err
				throw err

			} finally
				building.val = false
			
		} else {
			// some other thread is building the service
			// so just wait for it to finish
			while (instance.val == null && building.val) {
				// JS doesn't have an Actor.sleep() but then again
				// JS shouldn't give us threading issues!
				Actor.sleep(10ms)
			}

			// hope the error hasn't been cleared before we get a change to throw it!
			err := buildErr.val
			if (err != null)
				throw err
		}
		
		unsafe = (Unsafe?) instance.val
		return unsafe.val
	}

	Void setInstance(Obj instance) {
		this.instance.val = Unsafe(instance)
		this.def.noOfInstancesRef.incrementAndGet
		echo("$def.serviceIds = ${this.def.noOfInstancesRef.val}")
	}
	
	private Obj build(Scope currentScope) {
		instance := def.build(currentScope)
		def.callBuildHooks(currentScope, instance)
		return instance
	}
	
	Void destroy() {
		instance.val = null
		building.val = false
	}
	
	override Str toStr() { def.toStr }
}
