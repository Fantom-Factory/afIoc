
internal const class IocMessages {
	
	static Str unrecognisedModuleMethods(Type moduleType, Method[] methods) {
		"Module class ${moduleType.qname} contains unrecognised public methods: ${methods}"		
	}
	
    static Str buildMethodConflict(Str serviceId, Str conflict, Str existing) {
        "Service ${serviceId} (defined by ${conflict}) conflicts with previously defined service defined by ${existing}."
    }
	
	static Str bindMethodMustBeStatic(Str methodId) {
		"Method ${methodId} appears to be a service binder method, but is an instance method, not a static method."
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
	
	static Str oneShotLockViolation() {
		"Method may no longer be invoked."
	}

//	// service-wrong-interface=Service '%s' implements interface %s, which is not compatible with the requested type %s.
//	static Str serviceWrongType(Str serviceId, Type actualType, Type requestedType) {
//		"Service '${serviceId}' implements interface ${actualType}, which is not compatible with the requested type ${requestedType}."
//	}
	
	// many-service-matches=Service interface %s is matched by %d services: %s. Automatic dependency resolution requires that exactly one service implement the interface.
	static Str manyServiceMatches(Type serviceType, Str[] ids) {
		"Service mixin ${serviceType} is matched by ${ids.size} services: " + ids.join(", ") + ". Automatic dependency resolution requires that exactly one service implement the interface."
	}
	
//	// error-building-service=Error building service proxy for service '%s' (at %s): %s
//	static Str errorBuildingService(Str serviceId, ServiceDef serviceDef, Err cause) {
//		"Error building service proxy for service '${serviceId}' (at ${serviceDef}): ${cause}"
//	}
//	
//	// recursive-module-constructor=The constructor for module class %s is recursive: it depends on itself in some way. \n The constructor, %s, is in some way is triggering a service builder, decorator or contribution method within the class.
//	static Str recursiveModuleConstructor(Type moduleType, Method constructor) {
//		"The constructor for module class ${moduleType} is recursive: it depends on itself in some way. \n The constructor, ${constructor}, is in some way is triggering a service builder, decorator or contribution method within the class."
//	}
//	
//	// instantiate-builder-error=Unable to instantiate class %s as a module: %s
//	static Str instantiateBuilderError(Type moduleType, Err cause) {
//		"instantiate-builder-error=Unable to instantiate class ${moduleType} as a module: ${cause}"
//	}
}
