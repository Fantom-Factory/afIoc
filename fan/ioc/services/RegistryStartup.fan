
** (Service) - 
** Executes a series of (user defined) operations when the `Registry` starts up. Operations are 
** defined by contributing listeners to the 'RegistryStartup' service. For example, add the 
** following to your module:
** 
**   @Contribute
**   static Void contributeRegistryStartup(OrderedConfig conf, MyService myService) {
**     conf.add |->| {
**       myService.startup()
**     }
**   }
** 
** @uses OrderedConfig of |->|
const mixin RegistryStartup { }



internal const class RegistryStartupImpl : RegistryStartup {

	private const ThreadStash 	stash
	
	private |->|[]? startups {
		get { stash["startups"] }
		set { stash["startups"] = it }
	}	

	new make(|->|[] startups, ThreadStashManager stashManager) {
		this.stash		= stashManager.createStash(ServiceIds.registryStartup) 
		this.startups 	= startups
	}

	internal Void go(OpTracker tracker) {
		tracker.track("Running Registry Startup contributions") |->| {
			startups.each { it() }
			
			startups.clear
			stash.clear
		}
	}
}
