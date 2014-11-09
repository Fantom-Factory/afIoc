using afConcurrent

internal const class CachingTypeLookup {
	private const AtomicMap 	cache := AtomicMap() { it.keyType=Type#; it.valType=ServiceDef[]# }
	private const ServiceDef[]	serviceDefs
	
	new make(ServiceDef[] serviceDefs) {
		this.serviceDefs = serviceDefs
	}
	
	ServiceDef[] findChildren(Type type) {
		typeNonNull := type.toNonNullable
		return cache.getOrAdd(typeNonNull) |key -> Obj| {
			serviceDefs.findAll |def| { def.matchesType(typeNonNull) }
		}
	}
}