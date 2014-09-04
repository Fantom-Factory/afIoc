using concurrent
using afBeanUtils::NotFoundErr

** (Service) - 
** Maintains a collection of named 'ActorPools'. Use to keep tabs on your resources, particularly 
** useful when creating [SynchronizedMap]`afConcurrent::SynchronizedMap` and 
** [SynchronizedList]`afConcurrent::SynchronizedList` instances.
** 
** IoC itself uses an 'ActorPool' named 'afIoc.system'. Contribute your own via your 'AppModule':
** 
** pre>
** @Contribute { serviceType=RegistryShutdownHub# }
** static Void contributeActorPools(Configuration config) {
**   config["myPool"] = ActorPool() { it.name = "MyPool" }
** }
** <pre  
** 
** Note it is always a good idea to name your 'ActorPools' for debugging reasons.
** 
** @since 1.6.0
** 
** @uses Configuration of 'Str:ActorPool'
const mixin ActorPools {

	** Returns the 'ActorPool' mapped to the given name, or throws a 'NotFoundErr' if it doesn't exist.
	@Operator
	abstract ActorPool get(Str name)

	** Returns a map of 'ActorPool' names and the number of times it's been requested. 
	abstract Str:Int stats()

}

internal const class ActorPoolsImpl : ActorPools {
	
	const Str:ActorPool	actorPools
	const Str:AtomicInt usageStats
	
	new make(Str:ActorPool actorPools) {
		this.actorPools = actorPools
		
		counts := Str:AtomicInt[:]
		actorPools.keys.each |k| { 
			counts[k] = AtomicInt()
		}
		this.usageStats = counts
	}
	
	@Operator
	override ActorPool get(Str name) {
		pool := actorPools[name] ?: throw ActorPoolNotFoundErr("There is no ActorPool with the name: ${name}", actorPools.keys)
		usageStats[name].incrementAndGet
		return pool
	}
	
	** Returns a map of 'ActorPool' names and the number of times it's been requested. 
	override Str:Int stats() {
		usageStats.map { it.val }
	}
}

@NoDoc
const class ActorPoolNotFoundErr : IocErr, NotFoundErr {
	override const Str?[] availableValues
	
	new make(Str msg, Obj?[] availableValues, Err? cause := null) : super(msg, cause) {
		this.availableValues = availableValues.map { it?.toStr }.sort
	}
	
	override Str toStr() {
		NotFoundErr.super.toStr		
	}
}