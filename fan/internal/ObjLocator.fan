
** An internal mixin used to decouple RegistryImpl 
internal const mixin ObjLocator {

    abstract Obj? trackServiceById(Str serviceId, Bool checked)

    abstract Obj? trackDependencyByType(Type dependencyType, Bool checked)

    abstract Obj trackAutobuild(Type type, Obj?[]? initParams, [Field:Obj?]? fieldVals)

	abstract Obj trackCreateProxy(Type mixinType, Type? implType, Obj?[]? ctorArgs, [Field:Obj?]? fieldVals)
	
	abstract Str[] serviceIds()

	abstract InjectionUtils injectionUtils()
	
	abstract ServiceBuilders serviceBuilders()
}
