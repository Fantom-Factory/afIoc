
@Js
internal mixin ErrMsgs {
	
	// ---- RegistryBuilder Messages --------------------------------------------------------------
	
	static Str regBuilder_moduleAlreadyAdded(Type module) {
		"Module $module.qname has already been added - ignoring it this time round."
	}
	
	static Str regBuilder_podAlreadyAdded(Pod pod) {
		"Pod $pod.name has already been added - ignoring it this time round."
	}
	
	static Str regBuilder_invalidRegistryValue(Str key, Type wrongType, Type rightType) {
		"Registry option '$key' is a $wrongType.qname, it should be a $rightType.qname"
	}
	
	static Str errorInServiceDefinitonMethod(Str methodId, Err cause) {
		"Error invoking service definition method ${methodId}: ${cause}"
	}

    static Str regBuilder_serviceAlreadyDefined(Str serviceId, Type conflictMod, Type existingMod) {
        "Service ${serviceId} from ${conflictMod.qname} has already been defined in ${existingMod.qname}"
    }

    static Str regBuilder_onlyOneOverrideAllowed(Str serviceId, Type conflictMod, Type existingMod) {
        "Can not override service ${serviceId} twice! ${conflictMod.qname} vs ${existingMod.qname}. One override must override the other override."
    }

    static Str regBuilder_overrideAlreadyDefined(Str overrideId, Type conflictMod, Type existingMod) {
        "Override Id '${overrideId}' from ${conflictMod.qname} has already been defined by ${existingMod.qname}"
    }

	static Str regBuilder_serviceIdNotFound(Str serviceId) {
		"Service ${serviceId} is not defined. Did you forget to define it in AppModule?"
	}

    static Str regBuilder_scopeAlreadyDefined(Str scopeId, Type conflictMod, Type existingMod) {
        "Scope '${scopeId}' from ${conflictMod.qname} has already been defined in ${existingMod.qname}"
    }

    static Str regBuilder_cannotRemoveModule(Type moduleType) {
        "Cannot remove ${moduleType.qname}"
    }

    static Str regBuilder_modulesShouldBeConst(Type moduleType) {
        "Module instances should be const - ${moduleType.qname}"
    }

	static Str regBuilder_ignoringModule(Type moduleType) {
        "Ignoring module - ${moduleType.qname}"
    }

	
	
	// ---- Scope Messages ------------------------------------------------------------------------

	static Str scope_scopeNotFound(Str scopeId) {
		"Could not find Scope '${scopeId}'"
	}
	
	static Str scope_scopesMayNotBeNested(Str scopeId, Str[] scopes) {
		"Nested scopes are not allowed: " + scopes.add(scopeId).join(" -> ")
	}

	static Str scope_invalidScopeNesting(Str scopeId, Str parentScopeId) {
		"App scope '${scopeId}' may not be nested inside threaded scope '${parentScopeId}'"
	}

	static Str scope_couldNotFindServiceById(Str serviceId, Str[] scopes) {
		"Could not find service ID '${serviceId}' in scopes: " + scopes.reverse.join(", ")
	}
	
	static Str scope_couldNotFindServiceByType(Type serviceType, Str[]? scopes) {
		msg := "Could not find service of Type ${serviceType.qname}"
		if (scopes != null)
			msg += " in scopes: " + scopes.reverse.join(", ")
		return msg
	}
	
	static Str scope_serviceRecursion(Str serviceId, Str[] serviceIds) {
		"Service recursion! Service '${serviceId}' relies on itself in some way: " + serviceIds.join(" -> ")
	}

	
	
	// ---- Srv Def Messages ----------------------------------------------------------------------
	
	static Str serviceBuilder_noId() {
		"Service does not define an ID"
	}

	static Str serviceBuilder_noType(Str id) {
		"Service '${id}' does not define a Type"
	}
	
	static Str serviceBuilder_noBuilder(Str id) {
		"Service '${id}' does not define a build function"
	}
	
	static Str serviceBuilder_aliasTypeDoesNotFitType(Type aliasType, Type type) {
		"Service Type alias ${aliasType.qname} does not fit service type ${type.qname}"
	}

	static Str serviceBuilder_scopeReserved(Str serviceId, Str scopeId) {
		"Scope '${scopeId}' is reserved and may not be declared by ${serviceId}"
	}
	
	static Str serviceBuilder_scopesNotFound(Str serviceId, Str[] scopes) {
		ids := scopes.sort.join(", ") { "'${it}'" }
		return "Could not find scope(s) ${ids} for service ${serviceId}"
	}

	static Str serviceBuilder_scopeIsThreaded(Str serviceId, Str scopeId) {
		"Service ${serviceId} can NOT match scope '${scopeId}' unless it is const."
	}
	
	static Str serviceBuilder_noScopesMatched(Str serviceId, Str[] scopes) {
		"Service ${serviceId} did not match any scope - " + scopes.sort.join(", ") + "\n - Try creating a threaded scope: regBuilder.addScope(\"thread\", true)\n - Or make ${serviceId} const."
	}
	
	static Str scopeBuilder_scopeReserved(Str id) {
		"Scope id '${id}' is reserved"
	}
	
	
	// ---- Service Store Messages ----------------------------------------------------------------
	
	static Str serviceStore_multipleServicesMatchType(Type serviceType, Str[] serviceIds) {
		"Service Type ${serviceType} matches multiple services: " + serviceIds.join(", ")
	}

	
	
	// ---- Contributions Messages ----------------------------------------------------------------

	static Str contributions_contributionMethodMustTakeConfig(Method method) {
		"Contribution method '$method.qname' must take a '${Configuration#.name}' obj as its first parameter"		
	}

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

	static Str contributions_contribitionHasBothIdAndType(Method method) {
		"Contribution method '$method.qname' defines both a serivce id AND a service type. Only 1 is allowed."
	}
	
	static Str contributionMethodDoesNotDefineServiceId(Method method) {
		"Contribution method $method.qname does not define a service ID."
	}

	static Str contributionServiceNotFound(Str serviceId, Method? method) {
		return method == null
			? "Could not find service '$serviceId' for contribution"
			: "Could not find service '$serviceId' as defined in contribution method ${method.qname}"
	}

	
	
	// ---- Orderer Messages ----------------------------------------------------------------------
	
	static Str orderer_configRecursion(Str[] nodeNames) {
		"Configuration ordering recursion! A configuration contribution depends on its self in some way : " + nodeNames.join(" -> ")
	}

	static Str orderer_configKeyAlreadyAdded(Str id) {
		"Configuration ordering already has a contribution with ID '$id'"
	}
	
	static Str orderer_configIsPlaceholder(Str placeholder) {
		"Configuration Id does not exist - $placeholder"
	}

	
	
	// ---- Autobuild Messages --------------------------------------------------------------------
	
	static Str autobuilder_funcNotImmutable(Str serviceId, Str key) {
		"Contribution Func '${key}' for service '${serviceId}' is NOT immutable"
	}

	static Str autobuilder_warnAutobuildingService(Type serviceType, Str serviceId) {
		"Building ${serviceType.qname} which is *also* defined as service '${serviceId} - unusual!"
	}
	
	static Str autobuilder_ctorsWithSameNoOfParams(Type serviceType, Int noOfParams) {
		"${serviceType.qname} has too many ctors with ${noOfParams} params - try annotating one with the @${Inject#.name} facet."
	}

	static Str autobuilder_couldNotFindAutobuildCtor(Type type, Type?[]? paramTypes) {
		val := "Could not find an autobuild ctor for ${type.qname}"
		if (paramTypes != null && !paramTypes.isEmpty)
			val += " with args " + paramTypes.map { it?.signature ?: "null" }
		return stripSys(val)
	}
	
	static Str autobuilder_fieldNotSetErr(Str fieldDesc, Method ctor) {
		"Field $fieldDesc was not set by ctor $ctor.signature"
	}

	static Str autobuilder_bindImplNotClass(Type impl) {
		"Service Implementation ${impl.qname} is a mixin and can not be instantiated"
	}
	
	static Str autobuilder_bindImplDoesNotFit(Type service, Type impl) {
		"Service Implementation ${impl.qname} does not fit ${service.qname}"
	}

	static Str autobuilder_couldNotFindImplType(Type serviceType) {
		"Could not find default implementation type '${serviceType}Impl'. Please provide this type, or bind the service mixin to a specific implementation type."
	}
	

	
	// ---- Dependency Provider Messages ----------------------------------------------------------
	
	static Str dependencyProviders_dependencyNotFound(InjectionCtx ctx) {
		type := ctx.field?.type ?: ctx.funcParam?.type
		return stripSys("No dependency matches type ${type.signature}. Try defining it as a service in your AppModule?")
	}
	
	static Str dependencyProviders_dependencyDoesNotFit(Type? providedArg, Type paramArg) {
		stripSys("Dependency of type ${providedArg?.signature} does not fit ${paramArg.signature}")
	}


	
	// ---- Func Provider Messages ----------------------------------------------------------------

	static Str funcProvider_mustNotHaveArgs(Type type) {
		stripSys("LazyFuncs for services must not declare arguments: ${type.signature}")
	}

	static Str funcProvider_couldNotFindService(Str serviceId) {
		"Could not find service ID '${serviceId}'"
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

	static Str scopeDestroyed(Str scopeId) {
		"Scope '${scopeId}' has been destroyed"
	}


	
	private static Str stripSys(Str str) {
		str.replace("sys::", "")
	}
}
