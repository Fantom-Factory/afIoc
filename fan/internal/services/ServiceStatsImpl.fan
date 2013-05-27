
** @since 1.2.0
internal const class ServiceStatsImpl : ServiceStats {
	
	private const ObjLocator objLocator
	
	new make(Registry registry) {
		this.objLocator = (ObjLocator) registry
	}
	
	override Str:ServiceStat stats() {
		objLocator.stats
	}
}
