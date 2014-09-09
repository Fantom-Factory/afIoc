
** An internal mixin used to decouple RegistryImpl 
internal const mixin ObjLocator {

    abstract Obj? trackServiceById(Str serviceId, Bool checked)

    abstract Obj trackAutobuild(Type type, Obj?[]? initParams, [Field:Obj?]? fieldVals)

	abstract Obj trackCreateProxy(Type mixinType, Type? implType, Obj?[]? ctorArgs, [Field:Obj?]? fieldVals)
	
	abstract ServiceDef? serviceDefByType(Type serviceType)
	abstract Bool typeMatchesService(Type serviceType)

	abstract Str[] serviceIds()

	abstract InjectionUtils 		injectionUtils()
	abstract ServiceBuilders 		serviceBuilders()
	abstract DependencyProviders	dependencyProviders()
}
