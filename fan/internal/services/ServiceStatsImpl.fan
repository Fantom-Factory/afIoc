
** @since 1.2.0
internal const class ServiceStatsImpl : ServiceStats {
	
	private const RegistryImpl registry
	
	new make(RegistryImpl registry) {
		this.registry = registry
	}
	
	override Str:ServiceStat stats() {
		registry.stats
	}
}
