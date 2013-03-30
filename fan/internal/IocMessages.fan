
// TODO: rename to InternalMsgs...?
internal const class IocMessages {

	// ---- Err Messages --------------------------------------------------------------------------

	static Str unrecognisedModuleMethods(Type moduleType, Method[] methods) {
		"Module class ${moduleType.qname} contains unrecognised public methods: ${methods}"		
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
	
	static Str errorInBindMethod(Str methodId, Err cause) {
		"Error invoking service binder method ${methodId}: ${cause}"
	}

	static Str noServiceMatchesType(Type serviceType) {
		"No service implements the mixin ${serviceType}."
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
	
	static Str buildMethodDoesNotDefineServiceId(Method method) {
		"Builder method $method.qname does not define a service ID. Rename it to ${method.qname}XXX where XXX is the service ID."
	}
	
	// many-service-matches=Service interface %s is matched by %d services: %s. Automatic dependency resolution requires that exactly one service implement the interface.
	static Str manyServiceMatches(Type serviceType, Str[] ids) {
		"Service mixin ${serviceType} is matched by ${ids.size} services: " + ids.join(", ") + ". Automatic dependency resolution requires that exactly one service implement the interface."
	}
	
//	// recursive-module-constructor=The constructor for module class %s is recursive: it depends on itself in some way. \n The constructor, %s, is in some way is triggering a service builder, decorator or contribution method within the class.
//	static Str recursiveModuleConstructor(Type moduleType, Method constructor) {
//		"The constructor for module class ${moduleType} is recursive: it depends on itself in some way. \n The constructor, ${constructor}, is in some way is triggering a service builder, decorator or contribution method within the class."
//	}
	
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
