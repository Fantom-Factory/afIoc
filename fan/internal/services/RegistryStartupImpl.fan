
internal const class RegistryStartupImpl : RegistryStartup {

	private const LocalStash 		stash		:= LocalStash(RegistryStartup#)
	
	private |->|[]? startups {
		get { stash["startups"] }
		set { stash["startups"] = it }
	}	

	new make(|->|[] startups) {
		this.startups = startups
	}
	
	internal Void go(OpTracker tracker) {
		tracker.track("Running Registry Startup contributions") |->| {
			startups.each { it() }
			
			startups.clear
			startups = null
		}
	}
}
