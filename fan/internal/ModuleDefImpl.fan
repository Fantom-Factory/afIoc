
internal const class ModuleDefImpl : ModuleDef {
	private const static Log log := Utils.getLog(ModuleDefImpl#)
	
	** prefix used to identify service builder methods
	private static const Str 			BUILD_METHOD_NAME_PREFIX 		:= "build"

	** prefix used to identify service contribution methods
	private static const Str 			CONTRIBUTE_METHOD_NAME_PREFIX 	:= "contribute"

	private static const Method[]		OBJECT_METHODS 					:= Obj#.methods
	
	override 	const Type 				moduleType
	override 	const Str:ServiceDef	serviceDefs
	

	new make(OpTracker tracker, Type moduleType) {
		this.moduleType = moduleType

		tracker.track("Inspecting module $moduleType.qname") |->| {
			serviceDefs := Str:ServiceDef[:] { caseInsensitive = true }
			
			methods := moduleType.methods.exclude |method| { OBJECT_METHODS.contains(method) || method.isCtor }
	
			grind(tracker, serviceDefs, methods)
			bind(tracker, serviceDefs, methods)
	
			// verify that every public method is meaningful to IoC. Any remaining methods may be 
			// typos, i.e. "createFoo" instead of "buildFoo"
			methods = methods.exclude { !it.isPublic }
			if (!methods.isEmpty)
				throw IocErr(IocMessages.unrecognisedModuleMethods(moduleType, methods))
			
			this.serviceDefs = serviceDefs
		}
	}


	// ---- ModuleDef Methods ---------------------------------------------------------------------
	
	override Str moduleId() {
		moduleType.qname
	}
	
	override Str toStr() {
		"Def for ${moduleId}"
	}
	
	
	// ---- Private Methods -----------------------------------------------------------------------

	private Void grind(OpTracker tracker, Str:ServiceDef serviceDefs, Method[] remainingMethods) {
		methods := moduleType.methods.dup.sort |Method a, Method b -> Int| { 
			a.name <=> b.name 
		}

		methods.each |method| {
			
			if (method.name.startsWith(BUILD_METHOD_NAME_PREFIX)) {
				tracker.track("Found builder method $method.qname") |->| {
					addServiceDefFromMethod(tracker, serviceDefs, method)
					remainingMethods.remove(method)
				}
				return
			}

			// TODO: @Startup
//			if (method.hasFacet(Startup#))) {
//				addStartupDef(method)
//				remainingMethods.remove(method)
//				return
//			}
		}
	}
	
	private Void addServiceDefFromMethod(OpTracker tracker, Str:ServiceDef serviceDefs, Method method) {
		serviceDef	:= StandardServiceDef {
			it.serviceId 	= extractServiceId(method)
			it.moduleId 	= this.moduleId
			it.serviceType	= method.returns
//			it.isEagerLoad 	= method.hasFacet(EagerLoad#)
			it.description	= "'$serviceId' : Builder method $method.qname"

			if (method.returns.isMixin)
				it.scope	= ScopeDef.perThread
			else
				it.scope 	= method.returns.isConst ? ScopeDef.perApplication : ScopeDef.perThread 
			
			serviceId 		:= it.serviceId
			it.source 		= |InjectionCtx ctx -> Obj| {
				ctx.track("Creating Serivce '$serviceId' via a builder method '$method.qname'") |->Obj| {
					log.info("Creating Service '$serviceId'")
					return InjectionUtils.callMethod(ctx, method, null)
				}
			}			
		}
		addServiceDef(tracker, serviceDefs, serviceDef)
	}	
	
    private Void addServiceDef(OpTracker tracker, Str:ServiceDef serviceDefs, ServiceDef serviceDef) {
		tracker.log("Adding service definition for service '$serviceDef.serviceId' -> ${serviceDef.serviceType.qname}")
		
		ServiceDef? existing := serviceDefs[serviceDef.serviceId]
		if (existing != null) {
			throw IocErr(IocMessages.buildMethodConflict(serviceDef.serviceId, serviceDef.toStr, existing.toStr))
		}
		
		serviceDefs[serviceDef.serviceId] = serviceDef
    }	
	
	private Str extractServiceId(Method method) {
		serviceId := stripMethodPrefix(method, BUILD_METHOD_NAME_PREFIX)

        if (serviceId.isEmpty)
            throw IocErr(IocMessages.buildMethodDoesNotDefineServiceId(method))
		
		return serviceId
	}
		
	private static Str stripMethodPrefix(Method method, Str prefix) {
		method.name[prefix.size..-1]
	}
	
	private Void bind(OpTracker tracker, Str:ServiceDef serviceDefs, Method[] remainingMethods) {
		Method? bindMethod := moduleType.method("bind", false)
		
		if (bindMethod == null)
			// No problem! Many modules will not have such a method.
			return
		
		tracker.track("Found binder method $bindMethod.qname") |->| {
			if (!bindMethod.isStatic)
				throw IocErr(IocMessages.bindMethodMustBeStatic(bindMethod))

			if (bindMethod.params.size != 1 || !bindMethod.params[0].type.fits(ServiceBinder#))
				throw IocErr(IocMessages.bindMethodWrongParams(bindMethod))

			binder := ServiceBinderImpl(bindMethod, this) |ServiceDef serviceDef| {
				addServiceDef(tracker, serviceDefs, serviceDef)
			}
			
			try {
				bindMethod.call(binder)			
			} catch (IocErr e) {
				throw e
			} catch (Err e) {
				throw IocErr(IocMessages.errorInBindMethod(bindMethod.qname, e), e)
			}
			
			binder.finish
			remainingMethods.remove(bindMethod)
		}
	}
}

