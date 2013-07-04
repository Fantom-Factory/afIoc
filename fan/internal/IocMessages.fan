
internal const class IocMessages {

	// ---- Err Messages --------------------------------------------------------------------------

	static Str invalidRegistryOptions(Str[] invalidKeys, Str[] validKeys) {
		invalidStr	:= invalidKeys.join(", ") 
		validStr	:= validKeys.join(", ") 
		return "The following are invalid registry options: $invalidStr - valid keys are $validStr"
	}
	
	static Str invalidRegistryValue(Str key, Type wrongType, Type rightType) {
		"Registry option '$key' is a $wrongType.qname, it should be a $rightType.qname"
	}

	static Str serviceNotStarted() {
		"IoC Service has not been started."		
	}

	static Str serviceStarted() {
		"IoC Service has already started."		
	}

	static Str moduleRecursion(Str[] modNames) {
		"Module recursion! A module references itself in some way: " + modNames.join(" -> ")
	}
	
	static Str moduleAlreadyAdded(Type module) {
		"Module $module.qname has already been added - ignoring it this time round."
	}
	
	static Str moduleMethodWithNoFacet(Method method, Type facetType) {
		"Module method $method.qname should be annotated with the @${facetType.name} facet"
	}
	
    static Str buildMethodConflict(Str serviceId, Str conflict, Str existing) {
        "Service ${serviceId} (defined by ${conflict}) conflicts with previously defined service defined by ${existing}."
    }
	
	static Str bindMethodMustBeStatic(Method method) {
		"Binder method ${method.qname} must be a static method."
	}

	static Str bindMethodWrongParams(Method method) {
		"Binder method ${method.qname} must only take one parameter of type 'ServiceBinder' : ${method.signature}"
	}
	
	static Str bindImplDoesNotFit(Type service, Type impl) {
		"Service Implementation ${impl.qname} does not fit ${service.qname}"
	}
	
	static Str bindImplNotClass(Type impl) {
		"Service Implementation ${impl.qname} can not be instantiated"
	}
	
	static Str perAppScopeOnlyForConstClasses(Type impl) {
		"'perApplication' scope is only for const classes : $impl.qname"
	}
	
	static Str errorInBindMethod(Str methodId, Err cause) {
		"Error invoking service binder method ${methodId}: ${cause}"
	}

	static Str noDependencyMatchesType(Type type) {
		"No dependency macthes type ${type.signature}."
	}

	static Str couldNotFindImplType(Type serviceType) {
		"Could not find default implementation type '${serviceType}Impl'. Please provide this type, or bind the service interface to a specific implementation type."
	}

	static Str serviceIdConflict(Str serviceId, ServiceDef existing, ServiceDef conflicting) {
		"Service id '${serviceId}' has already been defined by ${existing} and may not be redefined by ${conflicting}. \n You should rename one of the service builder methods."
	}
	
	static Str serviceIdNotFound(Str serviceId) {
		"Service id '${serviceId}' is not defined by any module."
	}

	static Str onlyOneCtorWithInjectFacetAllowed(Type serviceType, Int noOfCtors) {
		"Only 1 ctor is allowed to have the @${Inject#.name} facet, ${serviceType.qname} has ${noOfCtors}!"
	}
	
	static Str ctorsWithSameNoOfParams(Type serviceType, Int noOfParams) {
		"${serviceType.qname} has too many ctors with ${noOfParams} params - try annotating one with the @${Inject#.name} facet."
	}
	
	static Str builderMethodsMustBeStatic(Method method) {
		"Builder method $method.qname must be static"
	}
	
	static Str buildMethodDoesNotDefineServiceId(Method method) {
		"Builder method $method.qname does not define a service ID. Rename it to ${method.qname}XXX where XXX is the service ID."
	}
	
	static Str manyServiceMatches(Type serviceType, Str[] ids) {
		"Service mixin ${serviceType} is matched by ${ids.size} services: " + ids.join(", ") + ". \nAutomatic dependency resolution requires that exactly one service implement the interface. \nConsider using the @ServiceId facet."
	}
	
	static Str threadScopeInAppScope(Str owningServiceId, Str injectedServiceId) {
		"Can not inject ${ServiceScope.perThread.name} scoped service $injectedServiceId into ${ServiceScope.perApplication.name} scoped service $owningServiceId"
	}
	
	static Str cannotSetConstFields(Field field) {
		"To set const field '$field.qname' use a serialisation ctor: new make(|This|? f := null) { f?.call(this) }"
	}
	
	static Str serviceRecursion(Str[] serviceIds) {
		"Service recursion! A service relies on itself in some way: " + serviceIds.join(" -> ")
	}
	
	static Str contributionMethodMustBeStatic(Method method) {
		"Contribution method '$method.qname' must be static"
	}
	
	static Str contributionMethodMustTakeConfig(Method method) {
		"Contribution method '$method.qname' must take either an ${OrderedConfig#.name} or a ${MappedConfig#.name} as its first parameter"		
	}
	
	static Str contribitionHasBothIdAndType(Method method) {
		"Contribution method '$method.qname' defines both a serivce id AND a service type. Only 1 is allowed."
	}
	
	static Str contributionMethodDoesNotDefineServiceId(Method method) {
		"Contribution method $method.qname does not define a service ID."
	}

	static Str contributionMethodServiceIdDoesNotExist(Method method, Str serviceId) {
		"Service does not exist for ID '$serviceId' defined in contribution method ${method.qname}."
	}

	static Str contributionMethodServiceTypeDoesNotExist(Method method, Type serviceType) {
		"Service does not exist for Type '$serviceType.qname' defined in contribution method ${method.qname}."
	}
	
	static Str orderedConfigTypeIsGeneric(Type contribType, Str serviceId) {
		"Ordered configuration for service '$serviceId' MUST be parameterised - e.g. Str[]"
	}

	static Str orderedConfigTypeMismatch(Type? objType, Type listType) {
		"Contribution of type ${objType?.signature} does not match service configuration list type of $listType.signature"
	}

	static Str mappedConfigTypeIsGeneric(Type contribType, Str serviceId) {
		"Mapped configuration for service '$serviceId' MUST be parameterised - e.g. [Str:Obj]"
	}
	
	static Str mappedConfigTypeMismatch(Str type, Type? objType, Type mapType) {
		"Contribution of type ${objType?.signature} does not match service configuration $type type of $mapType.signature"
	}
	
	static Str configRecursion(Str[] nodeNames) {
		"Configuration ordering recursion! A configuration contribution depends on its self in some way : " + nodeNames.join(" -> ")
	}

	static Str configKeyAlreadyAdded(Str id) {
		"Configuration ordering already has a contribution with ID '$id'"
	}
	
	static Str configBadPrefix(Str constraint) {
		"Configuration constraints must start with either 'BEFORE:' or 'AFTER:' - $constraint"
	}

	static Str configIsPlaceholder(Str placeholder) {
		"Configuration Id does not exist - $placeholder"
	}
	
	static Str serviceOverrideNotImmutable(Str serviceId, Type serviceImpl) {
		"Override for Service '$serviceId (${serviceImpl.qname}) is not immutable"
	}
	
	static Str serviceOverrideDoesNotFitServiceDef(Str serviceId, Type serOverride, Type serDef) {
		"Override for service '$serviceId (${serOverride.qname}) does not fit the definition of ${serDef.qname}"
	}
	
	static Str serviceOverrideDoesNotExist(Str serviceId, Type serOverride) {
		"Overriding service '$serviceId' with ${serOverride.qname} maybe difficult, service '$serviceId' doesn't exist!"
	}
	
	static Str contribOverrideDoesNotExist(Str existingKeys, Str overrideKeys) {
		"Can not override mapped contribution(s) '$existingKeys' with `$overrideKeys` because '$existingKeys' do(es) not exist"
	}
	
	static Str configMappedKeyAlreadyDefined(Str existingKey) {
		"Key '$existingKey' has already been defined - try overriding it instead"
	}

	static Str configOverrideKeyAlreadyDefined(Str existingKey, Str overrideKey) {
		"Override for key '$existingKey' has already been defined - try overriding '$overrideKey' instead"
	}

	static Str configOverrideKeyAlreadyExists(Str existingKey) {
		"Override key '$existingKey' has already been defined - use a different override key"
	}
	
	static Str shutdownListenerError(Obj listener, Err cause) {
		"Error notifying ${listener} of registry shutdown: ${cause}"
	}
	
	static Str serviceIdDoesNotFit(Str serviceId, Type serviceType, Type fieldType) {
		"Service Id '${serviceId}' of type ${serviceType.signature} does not fit type ${fieldType.signature}"
	}
	
	static Str dependencyDoesNotFit(Type dependencyType, Type fieldType) {
		"Dependency of type ${dependencyType.signature} does not fit type ${fieldType.signature}"
	}
	
	static Str onlyOneDependencyProviderAllowed(Type type, Type[] dps) {
		"Only one Dependency Provider is allowed, but type ${type.signature} matches ${dps.size} : " + dps.map { it.qname }.join(", ")
	}
	
	static Str providerMethodArgDoesNotFit(Type providedArg, Type paramArg) {
		"Provided autobuild parameter '$providedArg.signature' does not fit parameter '$paramArg.signature'"
	}
	
	static Str fieldNotSetErr(Str fieldDesc, Method ctor) {
		"Field $fieldDesc was not set by ctor $ctor.signature"
	}
	
	static Str autobuildTypeHasToInstantiable(Type autobuildType) {
		"Autobuild types must be instantiable! - $autobuildType.qname"
	}
	
	static Str adviseMethodMustBeStatic(Method method) {
		"Advise method '$method.qname' must be static"
	}
	
	static Str adviseMethodMustTakeMethodAdvisorList(Method method) {
		"Advise method '$method.qname' must take a list of ${MethodAdvisor#.name}s as its first parameter. e.g. static Void ${method.name}(${MethodAdvisor#.name}[] methodAdvisors, ...) { ... }"
	}
	
	static Str typeCoercionFail(Type from, Type to) {
		"Could not coerce ${from.qname} to ${to.qname}"
	}
	
	static Str typeCoercionNotFound(Type from, Type to) {
		"Could not find coercion from ${from.qname} to ${to.qname}"
	}
	
	// ---- Proxy Service Messages ----------------------------------------------------------------
	
	static Str onlyMixinsCanBeProxied(Type mixinType) {
		"Only Mixins can be proxied - '$mixinType.qname'"
	}

	static Str proxiedMixinsMustBePublic(Type mixinType) {
		"Proxied mixins must be public - '$mixinType.qname'"
	}
	
	static Str adviceDoesNotMatchAnyServices(AdviceDef adviceDef, Str[] advisableServiceIds) {
		"Advisor method '${adviceDef.advisorMethod.qname} with serviceId glob '${adviceDef.serviceIdGlob}' does NOT match any proxy services. Advisable services: " + advisableServiceIds.join(", ")
	}
	

	// ---- One Shot Lock Messages ----------------------------------------------------------------

	static Str oneShotLockViolation(Str because) {
		"Method may no longer be invoked - $because"
	}

	static Str registryBuilt() {
		"Registry has already been built"
	}

	static Str registryStarted() {
		"Registry has already started"
	}

	static Str registryShutdown() {
		"Registry has already been shutdown"
	}

	static Str serviceDefined() {
		"Service has already been defined"
	}
}
