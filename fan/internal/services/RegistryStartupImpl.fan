
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
