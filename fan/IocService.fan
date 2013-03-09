using concurrent

const class IocService : Service, ObjLocator {
	private static const Log 	log 	:= Log.get(IocService#.name)
	private const IocState 		state 	:= IocState(ActorPool()) 
	
	override Void onStart() {
		withState |state| {
			log.info("Starting IOC...");
		
			try {
				regBuilder := RegistryBuilder()
				
				moduleNames := Env.cur.index("afIoc.module")
				moduleNames.each |moduleName| {
					regBuilder.addType(Type.find(moduleName))
				}
				
				registry := regBuilder.build.performRegistryStartup
			
				state.registry = registry
				
			} catch (Err e) {
				log.err("Err starting IOC", e)
			}
		}
	}

	override Void onStop() {
		withState |state| {
			log.info("Stopping IOC...");
			state.registry.shutdown
		}
	}
	
	// ---- Registry Methods --------------------------------------------------
	
	override Obj serviceById(Str serviceId) {
        getState |state| {
			state.registry.serviceById(serviceId)
        }
	}
	
	override Obj serviceByType(Type serviceType) {
        getState |state| {
			state.registry.serviceByType(serviceType)
        }
	}

	override Obj autobuild(Type type, Str description := "Building '$type.qname'") {
        getState |state| {
			state.registry.autobuild(type, description)
        }
	}
	
	// ---- Private -----------------------------------------------------------
	
	private Void withState(|IocState| f) {
		state.send(f.toImmutable)
	}

	private Obj? getState(|IocState -> Obj?| f) {
		// use Unsafe as the services are neither const nor serializable 
		fImmute := f.toImmutable
		return state.send(|state->Unsafe| {
			Unsafe(fImmute.call(state))
		}).get->val
	}
}

internal const class IocState : Actor {
	private const Log log 			:= Log.get(typeof.name)
	private const LocalStash stash	:= LocalStash(typeof)
	
	new make(ActorPool ap) : super(ap) { } 
	
	Registry registry {
		get { stash["registry"] }
		set { stash["registry"] = it }
	}
	
	override Obj? receive(Obj? msg) {
		func := (msg as |Obj?->Obj?|)

		try {
			return func.call(this)
			
		} catch (Err e) {
			// if the func has a return type, then an the Err is rethrown on assignment
			// else we log the Err so the Thread doesn't fail silently
			if (func.returns == Void#)
				log.err("receive()", e)
			throw e
		}
	}	
}