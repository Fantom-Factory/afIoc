
internal class ModuleDefImpl : ModuleDef {
	
	** The prefix used to identify service builder methods.
	private static const Str BUILD_METHOD_NAME_PREFIX 		:= "build"

	** The prefix used to identify service contribution methods.
	private static const Str CONTRIBUTE_METHOD_NAME_PREFIX 	:= "contribute"

	private static const Method[] OBJECT_METHODS 			:= Obj#.methods
	
	override 	Type 				moduleType
	override 	Str:ServiceDef		serviceDefs				:= Str:ServiceDef[:] { caseInsensitive = true }
	
	new make(Type moduleType) {
		this.moduleType = moduleType

		// Want to verify that every public method is meaningful to Tapestry IoC. Remaining methods
		// might have typos, i.e., "createFoo" that should be "buildFoo".
		methods := moduleType.methods.exclude |method| { OBJECT_METHODS.contains(method) || method.isCtor }

		grind(methods)
		bind(methods)

		if (!methods.isEmpty)
			throw IocErr(IocMessages.unrecognisedModuleMethods(moduleType, methods))		
	}

	
	
	// ---- ModuleDef Methods ---------------------------------------------------------------------
		
    Void addServiceDef(ServiceDef serviceDef) {
		ServiceDef? existing := serviceDefs[serviceDef.serviceId]
		if (existing != null) {
			throw IocErr(IocMessages.buildMethodConflict(serviceDef.serviceId, serviceDef.toStr, existing.toStr))
		}
		
		serviceDefs[serviceDef.serviceId] = serviceDef
    }	

	override Str loggerName() {
		moduleType.name
	}
	
	
	
	// ---- Private Methods -----------------------------------------------------------------------

	private Void grind(Method[] remainingMethods) {
		methods := moduleType.methods.dup.sort |Method a, Method b -> Int| { 
			a.name <=> b.name 
		}

		methods.each |method| {
			
			if (method.name.startsWith(BUILD_METHOD_NAME_PREFIX)) {
				addServiceDefFromMethod(method)
				remainingMethods.remove(method)
				return
			}

			// TODO:
//			if (method.hasFacet(Startup#))) {
//				addStartupDef(method)
//				remainingMethods.remove(method)
//				return
//			}
		}
	}
	
	private Void addServiceDefFromMethod(Method method) {
		serviceDef	:= ServiceDefImpl {
			it.serviceId 	= extractServiceId(method)
			it.serviceType	= method.returns
//			it.isEagerLoad 	= method.hasFacet(EagerLoad#)
			it.description	= method.toStr
			it.source		= |->Obj| { method.call }	// TODO: inject services into method
		}
		
		addServiceDef(serviceDef)
	}	
	
	private Str extractServiceId(Method method) {
		Str? serviceId
		
		if (serviceId == null)
			serviceId = stripMethodPrefix(method, BUILD_METHOD_NAME_PREFIX)

        // If the method name was just "build()", then work from the return type.
        if (serviceId == "")
            serviceId = method.returns.name
		
		return serviceId
	}
		
	private static Str stripMethodPrefix(Method method, Str prefix) {
		method.name[prefix.size..-1]
	}
	
	private Void bind(Method[] remainingMethods) {
		Method? bindMethod := moduleType.method("bind", false)
		
		if (bindMethod == null)
			// No problem! Many modules will not have such a method.
			return
		
		if (!bindMethod.isStatic)
			throw IocErr(IocMessages.bindMethodMustBeStatic(bindMethod.qname))
		
		binder := ServiceBinderImpl(this, bindMethod)
		
		try {
			bindMethod.call(binder)			
		} catch (Err e) {
			throw IocErr(IocMessages.errorInBindMethod(bindMethod.qname, e), e)
		}
		
		binder.finish
		remainingMethods.remove(bindMethod)	
	}
}

