using afConcurrent::LocalMap

** (Service) - Contribute functions to be executed on `Registry` startup.
**  
** Functions for registry startup need *not* be immutable.
** 
** Example usage:
** 
** pre>
** class AppModule {
**     @Contribute { serviceType=RegistryStartup# }
**     static Void contributeRegistryStartup(Configuration conf, MyService myService) {
**         conf.add |->| { myService.startup() }
**     }
** }
** <pre
** 
** @uses Configuration of '|->| []'
const mixin RegistryStartup {
	internal abstract Void startup(OpTracker tracker)
	
	** Miscellaneous method that returns a printed list of all the registry services and their lifecycle status. 
	abstract Str printServiceList()

	** Miscellaneous method that returns the Alien-Factory banner.
	abstract Str printBanner()
}



internal const class RegistryStartupImpl : RegistryStartup {
	private const LocalMap startups
	
	@Inject private const Registry		registry
	@Inject private const RegistryMeta	meta
	
	// Map needs to be keyed on Str so IoC can auto-generate keys in add()
	new make(Str:|->| startups, ThreadLocalManager localManager, |This|in) {
		in(this)
		this.startups = localManager.createMap("afIoc.StartupListeners")
		this.startups.map = startups
	}

	override Void startup(OpTracker tracker) {
		tracker.track("Running Registry Startup contributions") |->| {
			// wrapping errs in an IocErr dosn't give us anything here
			startups.map.each | |->| func, Str id| { func.call }
			startups.clear
			startups.localRef.cleanUp
		}
	}
	
	override Str printServiceList() {
		stats := registry.serviceDefinitions.vals
		srvcs := "\n\n${stats.size} Services:\n\n"
		maxId := (Int) stats.reduce(0) |size, stat| { ((Int) size).max(stat.serviceId.size) }
		unreal:= 0
		stats.each {
			srvcs	+= it.serviceId.padl(maxId) + ": ${it.lifecycle.name.toDisplayName}\n"
			if (it.lifecycle == ServiceLifecycle.defined)
				unreal++
		}
		perce := (100d * unreal / stats.size).toLocale("0.00")
		srvcs += "\n${perce}% of services are unrealised (${unreal}/${stats.size})\n"
		return srvcs
	}

	override Str printBanner() {
		heading := (Str) (meta.options["afIoc.bannerText"] ?: "Err...")
		title := "\n"
		title += Str<|   ___    __                 _____        _                  
		                / _ |  / /_____  _____    / ___/__  ___/ /_________  __ __ 
		               / _  | / // / -_|/ _  /===/ __// _ \/ _/ __/ _  / __|/ // / 
		              /_/ |_|/_//_/\__|/_//_/   /_/   \_,_/__/\__/____/_/   \_, /  
		              |>
		first := true
		while (!heading.isEmpty) {
			banner := heading.size > 52 ? heading[0..<52] : heading
			heading = heading[banner.size..-1]
			banner = first ? (banner.padl(52, ' ') + " /___/   \n") : (banner.padr(52, ' ') + "\n")
			title += banner
			first = false
		}
		title 	+= "\n"

		return title
	}
}
