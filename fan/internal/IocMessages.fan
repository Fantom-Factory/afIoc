
// TODO: rename to InternalMsgs...?
internal const class IocMessages {

	// ---- Err Messages --------------------------------------------------------------------------

	static Str serviceNotStarted() {
		"IoC Service has not been started."		
	}

	static Str serviceStarted() {
		"IoC Service has already started."		
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
		"Service Implementation ${impl.qname} is not instantiatable"
	}
	
	static Str perAppScopeOnlyForConstClasses(Type impl) {
		"'perApplication' scope is only for const classes : $impl.qname"
	}
	
	static Str errorInBindMethod(Str methodId, Err cause) {
		"Error invoking service binder method ${methodId}: ${cause}"
	}

	static Str noDependencyMatchesType(Type type) {
		"No dependency macthes type ${type}."
	}

	static Str couldNotFindImplType(Type serviceType) {
		"Could not find default implementation type '${serviceType}Impl'. Please provide this type, or bind the service interface to a specific implementation type."
	}

	static Str noConstructor(Type implementationClass) {
		"Type ${implementationClass} does not contain any constructors suitable for autobuilding."
	}
	
	static Str serviceIdConflict(Str serviceId, ServiceDef existing, ServiceDef conflicting) {
		"Service id '${serviceId}' has already been defined by ${existing} and may not be redefined by ${conflicting}. \n You should rename one of the service builder methods."
	}
	
	static Str serviceIdNotFound(Str serviceId) {
		"Service id '${serviceId}' is not defined by any module."
	}
	
	static Str oneShotLockViolation(Str because) {
		"Method may no longer be invoked - $because"
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
	
	// many-service-matches=Service interface %s is matched by %d services: %s. Automatic dependency resolution requires that exactly one service implement the interface.
	static Str manyServiceMatches(Type serviceType, Str[] ids) {
		"Service mixin ${serviceType} is matched by ${ids.size} services: " + ids.join(", ") + ". Automatic dependency resolution requires that exactly one service implement the interface."
	}
	
	static Str threadScopeInAppScope(Str owningServiceId, Str injectedServiceId) {
		"Can not inject ${ServiceScope.perThread.name} scoped service $injectedServiceId into ${ServiceScope.perApplication.name} scoped service $injectedServiceId"
	}
	
	static Str cannotSetConstFields(Field field) {
		"Can not set const field '$field.qname'. Either remove the 'const' keyword or the @${Inject#.name} facet."
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

	static Str orderedConfigTypeMismatch(Type objType, Type listType) {
		"Contribution of type $objType.qname does not match service configuration list type of $listType.qname"
	}

	
	
	static Str mappedConfigTypeIsGeneric(Type contribType, Str serviceId) {
		"Mapped configuration for service '$serviceId' MUST be parameterised - e.g. [Str:Obj]"
	}
	
	// ---- One Shot Lock Messages ----------------------------------------------------------------
	
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
