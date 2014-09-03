
internal const class ModuleDefImpl : ModuleDef {
	private const static Log log := Utils.getLog(ModuleDefImpl#)
	
	** prefix used to identify service builder methods
	private static const Str 			BUILD_METHOD_NAME_PREFIX 		:= "build"

	** prefix used to identify service contribution methods
	private static const Str 			CONTRIBUTE_METHOD_NAME_PREFIX 	:= "contribute"

	override 	const Type 				moduleType
	override 	const Str:ServiceDef	serviceDefs
	override 	const ContributionDef[]	contributionDefs
	override 	const AdviceDef[]		adviceDefs
	

	new make(OpTracker tracker, Type moduleType) {
		this.moduleType = moduleType

		tracker.track("Inspecting module $moduleType.qname") |->| {
			serviceDefs := Str:ServiceDef[:] { caseInsensitive = true }
			contribDefs	:= ContributionDef[,]
			adviceDefs	:= AdviceDef[,]
			
			grind(tracker, serviceDefs, contribDefs, adviceDefs)
			bind(tracker, serviceDefs)
			
			this.serviceDefs = serviceDefs
			this.contributionDefs = contribDefs
			this.adviceDefs = adviceDefs
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

	private Void grind(OpTracker tracker, Str:ServiceDef serviceDefs, ContributionDef[]	contribDefs, AdviceDef[] adviceDefs) {
		methods := moduleType.methods.rw.sort |Method a, Method b -> Int| { 
			a.name <=> b.name 
		}

		methods.each |method| {
			if (method.hasFacet(Build#)) {
				tracker.track("Found builder method $method.qname") |->| {
					addServiceDefFromMethod(tracker, serviceDefs, method)
				}
			} else if (method.name.startsWith("build"))
				throw IocErr(IocMessages.moduleMethodWithNoFacet(method, Build#))

			if (method.hasFacet(Contribute#)) {
				tracker.track("Found contribution method $method.qname") |->| {					
					addContribDefFromMethod(tracker, contribDefs, method)
				}
			} else if (method.name.startsWith("contribute"))
				throw IocErr(IocMessages.moduleMethodWithNoFacet(method, Contribute#))

			if (method.hasFacet(Advise#)) {
				tracker.track("Found advice method $method.qname") |->| {					
					addAdviceDefFromMethod(tracker, adviceDefs, method)
				}
			} else if (method.name.startsWith("advise"))
				throw IocErr(IocMessages.moduleMethodWithNoFacet(method, Advise#))
		}
	}
	
	
	// ---- Service Advice Methods ----------------------------------------------------------------

	private Void addAdviceDefFromMethod(OpTracker tracker, AdviceDef[] adviceDefs, Method method) {
		if (!method.isStatic)
			throw IocErr(IocMessages.adviseMethodMustBeStatic(method))
		if (method.params.isEmpty || !method.params[0].type.fits(MethodAdvisor#.toListOf))
			throw IocErr(IocMessages.adviseMethodMustTakeMethodAdvisorList(method))
		
		advise := (Advise) Slot#.method("facet").callOn(method, [Advise#])	// Stoopid F4

		adviceDef := StandardAdviceDef {
			it.serviceType		= advise.serviceType
			it.serviceIdGlob	= advise.serviceId
			it.advisorMethod	= method
			it.optional			= advise.optional
		}
		
		tracker.log("Adding advice for services $adviceDef.serviceIdGlob")
		adviceDefs.add(adviceDef)
	}

	
	// ---- Service Contribution Methods ----------------------------------------------------------

	private Void addContribDefFromMethod(OpTracker tracker, ContributionDef[] contribDefs, Method method) {
		if (!method.isStatic)
			throw IocErr(IocMessages.contributionMethodMustBeStatic(method))
		if (method.params.isEmpty || method.params[0].type != Configuration#)
			throw IocErr(IocMessages.contributionMethodMustTakeConfig(method))
		
		contribute := (Contribute) Slot#.method("facet").callOn(method, [Contribute#])	// Stoopid F4

		contribDef	:= StandardContributionDef {
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
	
	private Void addServiceDefFromMethod(OpTracker tracker, Str:ServiceDef serviceDefs, Method method) {
		if (!method.isStatic)
			throw IocErr(IocMessages.builderMethodsMustBeStatic(method))

		scope := method.returns.isConst ? ServiceScope.perApplication : ServiceScope.perThread
		
		build := (Build) Slot#.method("facet").callOn(method, [Build#])	// Stoopid F4 
		if (build.scope != null)
			scope = build.scope
		
		serviceDef	:= StandardServiceDef {
			it.serviceId 	= build.serviceId ?: extractServiceIdFromBuilderMethod(method)
			it.moduleId 	= this.moduleId
			it.serviceType	= method.returns
			it.description	= "$serviceId : Builder method $method.qname"
			it.scope 		= scope 
			it.noProxy		= build.disableProxy 
			it.serviceBuilderRef.val = fromBuildMethod(it, method) 
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

	private Str extractServiceIdFromBuilderMethod(Method method) {
		serviceId := stripMethodPrefix(method, BUILD_METHOD_NAME_PREFIX)

        if (serviceId.isEmpty)
            throw IocErr(IocMessages.buildMethodDoesNotDefineServiceId(method))
		
		return serviceId
	}

	
	// ---- Binder Methods ------------------------------------------------------------------------

	private Void bind(OpTracker tracker, Str:ServiceDef serviceDefs) {
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
		}
	}

	private static Str stripMethodPrefix(Method method, Str prefix) {
		if (method.name.lower.startsWith(prefix.lower))
			return method.name[prefix.size..-1]
		else
			return ""
	}
}

