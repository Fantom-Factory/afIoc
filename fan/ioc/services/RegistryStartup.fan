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
	
	** Returns a printed list of all the registry services and their lifecycle status. 
	abstract Str printServiceList()

	** Returns the Alien-Factory banner.
	abstract Str printBanner()
}



internal const class RegistryStartupImpl : RegistryStartup {
	private const LocalList startups
	
	@Inject private const ServiceStats	stats
	@Inject private const RegistryMeta	meta
	
	new make(|->|[] startups, ThreadLocalManager localManager, |This|in) {
		in(this)
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
	
	override Str printServiceList() {
		stats := this.stats.stats.vals.sort |s1, s2| { s1.serviceId <=> s2.serviceId }
		srvcs := "\n\n${stats.size} Services:\n\n"
		maxId := (Int) stats.reduce(0) |size, stat| { ((Int) size).max(stat.serviceId.size) }
		unreal:= 0
		stats.each {
			srvcs	+= it.serviceId.padl(maxId) + ": ${it.lifecycle}\n"
			if (it.lifecycle == ServiceLifecycle.DEFINED)
				unreal++
		}
		perce := (100d * unreal / stats.size).toLocale("0.00")
		srvcs += "\n${perce}% of services are unrealised (${unreal}/${stats.size})\n"
		return srvcs
	}

	override Str printBanner() {
		// TODO: afBedSheet-1.3.10 remove 'bannerText' when live
		heading := (Str?) (meta.options["afIoc.bannerText"] ?: meta.options["bannerText"]) ?: "Err..."
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
