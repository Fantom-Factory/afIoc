
** An internal mixin used to decouple RegistryImpl 
internal const mixin ObjLocator {

    abstract Obj? trackServiceById(Str serviceId, Bool checked)

    abstract Obj? trackDependencyByType(Type dependencyType, Bool checked)

    abstract Obj trackAutobuild(Type type, Obj?[]? initParams, [Field:Obj?]? fieldVals)

	// no-op - should be in Configuration
	abstract Obj trackCreateProxy(Type mixinType, Type? implType, Obj?[]? ctorArgs, [Field:Obj?]? fieldVals)

	// no-op
	abstract Obj trackInjectIntoFields(Obj service)	

	// no-op
	abstract Obj? trackCallMethod(Method method, Obj? instance, Obj?[]? providedMethodArgs)	

	// should be no-op
	abstract ServiceDef? serviceDefById(Str serviceId)
	
	// no-op
	abstract ServiceDef? serviceDefByType(Type serviceType) 
	
	abstract Str[] serviceIds()
}
