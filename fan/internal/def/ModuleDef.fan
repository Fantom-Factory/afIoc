
internal class ModuleDef {
	private const static Log 		log := Utils.getLog(ModuleDef#)
	
	private static const Str 		BUILD_METHOD_NAME_PREFIX 		:= "build"
	private static const Str 		OVERRIDE_METHOD_NAME_PREFIX 	:= "override"
	private static const Str 		CONTRIBUTE_METHOD_NAME_PREFIX 	:= "contribute"

	Type 					moduleType
	ContributionDef[]		contribDefs		:= ContributionDef[,]
	AdviceDef[]				adviceDefs		:= AdviceDef[,]
	Str:ServiceDefMutable	serviceDefs		:= Str:ServiceDefMutable[:] { caseInsensitive = true }
//	ServiceDef[]			serviceOverrides

	private OpTracker tracker

	new make(OpTracker tracker, Type moduleType) {
		this.moduleType = moduleType
		this.tracker	= tracker

		tracker.track("Inspecting module $moduleType.qname") |->| {			
			grind
			bind
		}
	}


	// ---- ModuleDef Methods ---------------------------------------------------------------------
	
	Str moduleId() {
		moduleType.qname
	}
	
	override Str toStr() {
		"Def for ${moduleId}"
	}
	
	
	// ---- Private Methods -----------------------------------------------------------------------

	private Void grind() {
		methods := moduleType.methods.rw.sort |Method a, Method b -> Int| { 
			a.name <=> b.name 
		}

		methods.each |method| {
			if (method.hasFacet(Build#)) {
				tracker.track("Found builder method $method.qname") |->| {
					addServiceDefFromMethod(method)
				}
			} else if (method.name.startsWith("build"))
				throw IocErr(IocMessages.moduleMethodWithNoFacet(method, Build#))

			if (method.hasFacet(Contribute#)) {
				tracker.track("Found contribution method $method.qname") |->| {					
					addContribDefFromMethod(method)
				}
			} else if (method.name.startsWith("contribute"))
				throw IocErr(IocMessages.moduleMethodWithNoFacet(method, Contribute#))

			if (method.hasFacet(Advise#)) {
				tracker.track("Found advice method $method.qname") |->| {					
					addAdviceDefFromMethod(method)
				}
			} else if (method.name.startsWith("advise"))
				throw IocErr(IocMessages.moduleMethodWithNoFacet(method, Advise#))
		}
	}
	
	
	// ---- Service Advice Methods ----------------------------------------------------------------

	private Void addAdviceDefFromMethod(Method method) {
		if (!method.isStatic)
			throw IocErr(IocMessages.adviseMethodMustBeStatic(method))
		if (method.params.isEmpty || !method.params[0].type.fits(MethodAdvisor#.toListOf))
			throw IocErr(IocMessages.adviseMethodMustTakeMethodAdvisorList(method))
		
		advise := (Advise) Slot#.method("facet").callOn(method, [Advise#])	// Stoopid F4

		adviceDef := AdviceDef {
			it.serviceType		= advise.serviceType
			it.serviceIdGlob	= advise.serviceId
			it.advisorMethod	= method
			it.optional			= advise.optional
		}
		
		tracker.log("Adding advice for services $adviceDef.serviceIdGlob")
		adviceDefs.add(adviceDef)
	}

	
	// ---- Service Contribution Methods ----------------------------------------------------------

	private Void addContribDefFromMethod(Method method) {
		if (!method.isStatic)
			throw IocErr(IocMessages.contributionMethodMustBeStatic(method))
		if (method.params.isEmpty || method.params[0].type != Configuration#)
			throw IocErr(IocMessages.contributionMethodMustTakeConfig(method))
		
		contribute := (Contribute) Slot#.method("facet").callOn(method, [Contribute#])	// Stoopid F4

		contribDef	:= ContributionDef {
			it.serviceId	= extractServiceIdFromContributionMethod(contribute, method)
			it.serviceType	= contribute.serviceType
			it.optional		= contribute.optional
			it.method		= method
		}
		
		serviceName := (contribDef.serviceId != null) ? "id '$contribDef.serviceId'" : "type '$contribDef.serviceType'" 
		tracker.log("Adding service contribution for service $serviceName")
		contribDefs.add(contribDef)
	}
	
	private Str? extractServiceIdFromContributionMethod(Contribute contribute, Method method) {
		
		if (contribute.serviceId != null && contribute.serviceType != null)
			throw IocErr(IocMessages.contribitionHasBothIdAndType(method))
		
		if (contribute.serviceId != null)
			return contribute.serviceId
		
		// resolve service from type - not id
		if (contribute.serviceType != null)
			return null
		
		serviceId := stripMethodPrefix(method, CONTRIBUTE_METHOD_NAME_PREFIX)

        if (serviceId.isEmpty)
            throw IocErr(IocMessages.contributionMethodDoesNotDefineServiceId(method))
		
		return serviceId
	}	
	
	
	// ---- Service Builder Methods ---------------------------------------------------------------
	
	private Void addServiceDefFromMethod(Method method) {
		if (!method.isStatic)
			throw IocErr(IocMessages.builderMethodsMustBeStatic(method))

		build := (Build) Slot#.method("facet").callOn(method, [Build#])	// Stoopid F4 

		serviceDef	:= ServiceDefMutable {
			it.moduleId 	= this.moduleId
			it.id 			= build.serviceId ?: method.returns.qname
			it.type			= method.returns
			it.scope 		= build.scope ?: (method.returns.isConst ? ServiceScope.perApplication : ServiceScope.perThread) 
			it.proxy		= build.proxy ?: ServiceProxy.ifRequired
			it.builderData	= method 
		}

		addServiceDef(serviceDef)
	}	

    private Void addServiceDef(ServiceDefMutable serviceDef) {
		tracker.log("Adding service definition for service '$serviceDef.id' -> ${serviceDef.type.qname}")
		
		if (serviceDefs.containsKey(serviceDef.id))
			throw IocErr(IocMessages.buildMethodConflict(serviceDef.id, serviceDef.toStr, serviceDefs[serviceDef.id].toStr))
		
		serviceDefs[serviceDef.id] = serviceDef
    }	


	
	// ---- Binder Methods ------------------------------------------------------------------------

	private Void bind() {
		Method? bindMethod := moduleType.method("bind", false)

		if (bindMethod == null)
			// No problem! Many modules will not have such a method.
			return

		tracker.track("Found binder method $bindMethod.qname") |->| {
			if (!bindMethod.isStatic)
				throw IocErr(IocMessages.bindMethodMustBeStatic(bindMethod))

			if (bindMethod.params.size != 1 || !bindMethod.params[0].type.fits(ServiceBinder#))
				throw IocErr(IocMessages.bindMethodWrongParams(bindMethod))

			binder := ServiceBinderImpl(bindMethod, this) |ServiceDefMutable serviceDef| {
				addServiceDef(serviceDef)
			}

			try {
				bindMethod.call(binder)
			} catch (IocErr e) {
				throw e
			} catch (Err e) {
				throw IocErr(IocMessages.errorInBindMethod(bindMethod.qname, e), e)
			}

			binder.finish
		}
	}

	private static Str stripMethodPrefix(Method method, Str prefix) {
		if (method.name.lower.startsWith(prefix.lower))
			return method.name[prefix.size..-1]
		else
			return ""
	}
}
