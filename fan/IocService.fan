
const class IocService : Service {
	static const Log log := Log.get(IocService#.name)
	
	override Void onStart() {
		try {			
			// TODO: Load modules
			log.info("Starting IOC...");
			
		} catch (Err e) {
			log.err("Err starting IOC", e)
		}
	}

	override Void onStop() {
		// TODO: kill everyone
	}
}
