using afConcurrent::LocalList

** (Service) - Contribute functions to be executed on `Registry` startup.
**  
** Functions for registry startup need *not* be immutable.
** 
** Example usage:
** 
** pre>
** class AppModule {
**     @Contribute { serviceType=RegistryStartup# }
**     static Void contributeRegistryStartup(OrderedConfig conf, MyService myService) {
**         conf.add |->| { myService.startup() }
**     }
** }
** <pre
** 
** @uses OrderedConfig of |->|
const mixin RegistryStartup {
	internal abstract Void startup(OpTracker tracker)
}



internal const class RegistryStartupImpl : RegistryStartup {
	private const LocalList startups
	
	new make(|->|[] startups, ThreadLocalManager localManager) {
		this.startups = localManager.createList("StartupListeners")
		this.startups.list = startups
	}

	override Void startup(OpTracker tracker) {
		tracker.track("Running Registry Startup contributions") |->| {
			startups.each { ((|->|) it).call }
			startups.clear
			startups.localRef.cleanUp
		}
	}
}
