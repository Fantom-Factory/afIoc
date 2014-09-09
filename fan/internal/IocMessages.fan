
internal const class IocMessages {

	// ---- Err Messages --------------------------------------------------------------------------
	
	static Str invalidRegistryValue(Str key, Type wrongType, Type rightType) {
		"Registry option '$key' is a $wrongType.qname, it should be a $rightType.qname"
	}

	static Str serviceNotStarted() {
		"IoC Service has not been started."		
	}

	static Str serviceStarted() {
		"IoC Service has already started."		
	}

	static Str moduleRecursion(Type[] modNames) {
		"Module recursion! A module references itself in some way: " + modNames.join(" -> ") { it.qname }
	}
	
	static Str moduleAlreadyAdded(Type module) {
		"Module $module.qname has already been added - ignoring it this time round."
	}
	
	static Str moduleMethodWithNoFacet(Method method, Type facetType) {
		"Module method $method.qname should be annotated with the @${facetType.name} facet"
	}
	
    static Str serviceAlreadyDefined(Str overrideId, SrvDef conflictDef, SrvDef existingDef) {
		conflict := conflictDef.buildData is Method ? "${conflictDef.buildData->qname}()" : "Service Definition in ${conflictDef.moduleId}"
		existing := existingDef.buildData is Method ? "${existingDef.buildData->qname}()" : "Service Definition in ${existingDef.moduleId}"
        return "Service Id '${overrideId}' from '${conflict}' has already been defined by '${existing}'"
    }
	
    static Str overrideAlreadyDefined(Str overrideId, SrvDef conflictDef, SrvDef existingDef) {
		conflict := conflictDef.buildData is Method ? "${conflictDef.buildData->qname}()" : "Service Definition in ${conflictDef.moduleId}"
		existing := existingDef.buildData is Method ? "${existingDef.buildData->qname}()" : "Service Definition in ${existingDef.moduleId}"
        return "Override Id '${overrideId}' from '${conflict}' has already been defined by '${existing}'"
    }
	
    static Str onlyOneOverrideAllowed(Str serviceId, SrvDef conflictDef, SrvDef existingDef) {
		conflict := conflictDef.buildData is Method ? "${conflictDef.buildData->qname}()" : "Service Definition in ${conflictDef.moduleId}"
		existing := existingDef.buildData is Method ? "${existingDef.buildData->qname}()" : "Service Definition in ${existingDef.moduleId}"
        return "Can not override service '${serviceId}' twice! '${conflict}' vs '${existing}'. One override must override the other override."
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
		"No dependency matches type ${type.signature}."
	}

	static Str couldNotFindImplType(Type serviceType) {
		"Could not find default implementation type '${serviceType}Impl'. Please provide this type, or bind the service mixin to a specific implementation type."
	}

	static Str serviceIdNotFound(Str serviceId) {
		"Service id '${serviceId}' is not defined."
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
	
	static Str manyServiceMatches(Type serviceType, Str[] ids) {
		"Service mixin ${serviceType} is matched by ${ids.size} services: " + ids.join(", ") + ". \nAutomatic dependency resolution requires that exactly one service implement the interface. \nConsider using the @ServiceId facet."
	}
	
	static Str threadScopeInAppScope(Str owningServiceId, Str injectedServiceId) {
		"Can not inject ${ServiceScope.perThread.name} scoped service $injectedServiceId into ${ServiceScope.perApplication.name} scoped service $owningServiceId"
	}
	
	static Str cannotSetConstFields(Field field) {
		"Can not set const field '$field.qname'. Try using a serialisation ctor: new make(|This|? f := null) { f?.call(this) }"
	}
	
	static Str serviceRecursion(Str[] serviceIds) {
		"Service recursion! A service relies on itself in some way: " + serviceIds.join(" -> ")
	}
	
	static Str contributionMethodMustBeStatic(Method method) {
		"Contribution method '$method.qname' must be static"
	}
	
	static Str contributionMethodMustTakeConfig(Method method) {
		"Contribution method '$method.qname' must take a '${Configuration#.name}' obj as its first parameter"		
	}
	
	static Str contribitionHasBothIdAndType(Method method) {
		"Contribution method '$method.qname' defines both a serivce id AND a service type. Only 1 is allowed."
	}
	
	static Str contributionMethodDoesNotDefineServiceId(Method method) {
		"Contribution method $method.qname does not define a service ID."
	}

	static Str contributionServiceNotFound(Method method, Str serviceId) {
		"Could not find service to match ID '$serviceId' as defined in contribution method ${method.qname}."
	}

	static Str contributionMethodsNotWanted(Str serviceId, Method[] methods) {
		"Service '$serviceId' does not take configuration contributions but has contribution method(s): " + methods.join(", ") { it.qname }
	}

	static Str configRecursion(Str[] nodeNames) {
		"Configuration ordering recursion! A configuration contribution depends on its self in some way : " + nodeNames.join(" -> ")
	}

	static Str configKeyAlreadyAdded(Str id) {
		"Configuration ordering already has a contribution with ID '$id'"
	}
	
	static Str configIsPlaceholder(Str placeholder) {
		"Configuration Id does not exist - $placeholder"
	}
	
	static Str serviceOverrideNotImmutable(Str serviceId) {
		"Override for Service '$serviceId is not immutable"
	}
	
	static Str shutdownListenerError(Str listener, Err cause) {
		"Error notifying ${listener} of registry shutdown: ${cause}"
	}

	static Str shutdownFuncNotImmutable(Str listener) {
		"Shutdown function '${listener}' is not immutable"
	}
	
	static Str serviceIdDoesNotFit(Str serviceId, Type serviceType, Type fieldType) {
		"Service Id '${serviceId}' of type ${serviceType.signature} does not fit type ${fieldType.signature}"
	}
	
	static Str dependencyDoesNotFit(Type? dependencyType, Type fieldType) {
		"Dependency of type ${dependencyType?.signature} does not fit type ${fieldType.signature}"
	}
	
	static Str onlyOneDependencyProviderAllowed(Type type, Type[] dps) {
		"Only one Dependency Provider is allowed, but type ${type.signature} matches ${dps.size} : " + dps.map { it.qname }.join(", ")
	}
	
	static Str providerMethodArgDoesNotFit(Type? providedArg, Type paramArg) {
		stripSys("Provided autobuild argument of type '${providedArg?.signature}' does not fit parameter '${paramArg.signature}'")
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
	
	static Str injectionUtils_ctorFieldType_wrongType(Field field, Type building) {
		"Field ${field.qname} does not belong to ${building.qname}"
	}
	
	static Str injectionUtils_ctorFieldType_nullValue(Field field) {
		"Field value for ${field.qname} is null"
	}
	
	static Str injectionUtils_ctorFieldType_valDoesNotFit(Obj val, Field field) {
		"Field value ${val.typeof.signature} does not fit field ${field.qname} ${field.type.signature}"
	}
	
	static Str injectionUtils_fieldIsStatic(Field field) {
		"Can not @Inject into static fields: ${field.qname}"
	}

	static Str multipleServicesDefined(Str serviceId, Str[] serviceIds) {
		"Service ID '${serviceId}' matches multiple services -> " + serviceIds.join(", ")
	}

	static Str builtinServicesCanNotBeOverridden(Str serviceId) {
		"Built-in services cannot be overridden: $serviceId"
	}

	static Str warnAutobuildingService(Str serviceId, Type serviceType) {
		"Autobuilding type '${serviceType.qname}' which is *also* defined as service '${serviceId} - unusual!"
	}



	// ---- Service Override Messages -------------------------------------------------------------

	static Str serviceOverrideDoesNotFitServiceDef(Str serviceId, Type serOverride, Type serDef) {
		"Override for service '$serviceId (${serOverride.qname}) does not fit the definition of ${serDef.qname}"
	}
		

	
	// ---- Proxy Service Messages ----------------------------------------------------------------
	
	static Str onlyMixinsCanBeProxied(Type mixinType) {
		"Only Mixins can be proxied - '$mixinType.qname'"
	}

	static Str proxiedMixinsMustBePublic(Type mixinType) {
		"Proxied mixins must be public - '$mixinType.qname'"
	}
	
	static Str adviceDoesNotMatchAnyServices(AdviceDef adviceDef) {
		"Advisor method '${adviceDef.advisorMethod.qname} with ${adviceDef.errMsg} does NOT match any proxy services."
	}
	
	
	
	// ---- One Shot Lock Messages ----------------------------------------------------------------

	static Str oneShotLockViolation(Str because) {
		"Method may no longer be invoked - $because"
	}

	static Str registryBuilt() {
		"IoC Registry has already been built"
	}

	static Str registryStarted() {
		"IoC Registry has already started"
	}

	static Str registryShutdown() {
		"IoC Registry has been shutdown"
	}

	static Str serviceDefined() {
		"IoC Service has already been defined"
	}
	
	
	
	// ---- Contributions Messages ----------------------------------------------------------------

	static Str contributions_configTypeIsGeneric(Type contribType, Str serviceId) {
		stripSys("Configuration for service '$serviceId' MUST be parameterised - e.g. Str[] or [Type:Obj]")
	}

	static Str contributions_configTypeMismatch(Str type, Type? contribType, Type serviceType) {
		stripSys("Contribution '${contribType?.signature}' does not match service configuration ${type} of ${serviceType.signature}")
	}

	static Str contributions_configKeyAlreadyDefined(Str existingKey, Obj value) {
		"Key '${existingKey}' already exists (try overriding it instead), with value - ${value}"
	}

	static Str contributions_configOverrideKeyAlreadyDefined(Str existingKey, Str overrideKey) {
		"Override for key '$existingKey' has already been defined - try overriding '$overrideKey' instead"
	}

	static Str contributions_configOverrideKeyAlreadyExists(Str existingKey) {
		"Override key '$existingKey' has already been defined - use a different override key"
	}

	static Str contributions_overrideDoesNotExist(Str existingKeys, Str overrideKeys) {
		"Cannot override contribution(s) '$existingKeys' with `$overrideKeys` because '$existingKeys' do(es) not exist"
	}

	static Str contributions_keyTypeNotKnown(Type keyType) {
		stripSys("Can not auto generate keys of type '${keyType.signature} - try using config.set() instead")
	}
	
	
	
	// ---- Helper Methods ------------------------------------------------------------------------
	
	private static Str stripSys(Str str) {
		str.replace("sys::", "")
	}
}
