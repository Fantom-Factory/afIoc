
** (Service) - Contribute functions to be executed on `Registry` start up.
**  
** Functions need not be immutable.
** 
** Example usage:
** 
** pre>
** class AppModule {
** 
**   @Contribute { serviceType=RegistryStartup# }
**   static Void contributeRegistryStartup(OrderedConfig conf, MyService myService) {
**     conf.add |->| {
**       myService.startup()
**     }
**   }
** }
** <pre
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
