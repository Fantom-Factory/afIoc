
@Js
internal const class FacetInspector : ModuleInspector {

	override Void inspect(RegistryBuilder bob, Obj module) {
		moduleType := module.typeof

		if (moduleType.hasFacet(SubModule#)) {
			subModule := (SubModule) moduleType.facet(SubModule#)
			subModule.modules.each { 
				bob.addModule(it)
			}
		}

		methods := moduleType.methods.rw.sort |Method a, Method b -> Int| { 
			a.name <=> b.name 
		}

		methods.each |method| {
			if (method.hasFacet(Build#))
				addServiceDef(bob, module, method)

			if (method.hasFacet(Override#))
				addServiceOverride(bob, module, method)

			if (method.hasFacet(Contribute#))
				addContribDef(bob, module, method)
		}
	}
	
	private Void addServiceDef(RegistryBuilder reg, Obj module, Method method) {
		buildFacet	:= (Build) method.facet(Build#) 
		instance 	:= method.isStatic ? null : module
		serviceId	:= buildFacet.serviceId ?: method.returns.qname
				
		bob    := (ServiceBuilderImpl) reg.addService
		srvDef := bob.srvDef
		srvDef.moduleId 	= module.typeof
		srvDef.id 			= serviceId
		srvDef.type			= method.returns
		srvDef.declaredScopes= buildFacet.scopes 
		srvDef.aliases		= buildFacet.aliases
		srvDef.aliasTypes	= buildFacet.aliasTypes
		srvDef.builder 		= |Scope currentScope->Obj?| {
			return callMethod(currentScope, method, instance, serviceId)
		}
	}
	
	private Void addServiceOverride(RegistryBuilder reg, Obj module, Method method) {
		overFacet	:= (Override) method.facet(Override#) 
		instance 	:= method.isStatic ? null : module		
		overId		:= overFacet.serviceId
		overType	:= overFacet.serviceType ?: method.returns
		
		bob    := overId != null ? reg.overrideService(overId) : reg.overrideServiceType(overType)
		ovrDef := ((ServiceOverrideBuilderImpl) bob).ovrDef
		ovrDef.moduleId 	= module.typeof
		ovrDef.serviceId	= overId
		ovrDef.serviceType	= overType
		ovrDef.scopes 		= overFacet.scopes 
		ovrDef.aliases		= overFacet.aliases
		ovrDef.aliasTypes	= overFacet.aliasTypes
		ovrDef.optional		= overFacet.optional
		ovrDef.overrideId	= overFacet.overrideId ?: ovrDef.overrideId
		ovrDef.gotService = |Str serviceId, Type serviceType| {
			if (!method.returns.fits(serviceType))
				throw IocErr(ErrMsgs.autobuilder_bindImplDoesNotFit(serviceType, method.returns))
			ovrDef.builder 	= |Scope currentScope->Obj?| {
				return callMethod(currentScope, method, instance, serviceId)
			}
		}
	}

	private Void addContribDef(RegistryBuilder reg, Obj module, Method method) {
		if (method.params.isEmpty || method.params[0].type != Configuration#)
			throw IocErr(ErrMsgs.contributions_contributionMethodMustTakeConfig(method))

		contribute := (Contribute) method.facet(Contribute#)

		instance 	:= method.isStatic ? null : module
		serviceId	:= (Str?)  null
		serviceType	:= (Type?) null

		if (contribute.serviceId != null)
			serviceId = contribute.serviceId

		if (contribute.serviceType != null)
			serviceId = contribute.serviceId

		if (contribute.serviceId != null && contribute.serviceType != null)
			throw IocErr(ErrMsgs.contributions_contribitionHasBothIdAndType(method))

		if (contribute.serviceId == null && contribute.serviceType == null)
			throw IocErr(ErrMsgs.contributionMethodDoesNotDefineServiceId(method))

		contribDef	:= ContribDef {
			it.moduleId		= module.typeof
			it.serviceId	= contribute.serviceId
			it.serviceType	= contribute.serviceType
			it.optional		= contribute.optional
			
			
			it.configFuncRef= Unsafe(|Configuration config| { config.scope.callMethod(method, instance, [config]) })
			it.method2		= method
		}
		
		reg._contribDefs.add(contribDef)
	}
	
	// call the method ourselves so we can set the serviceId
	private static Obj? callMethod(ScopeImpl scope, Method method, Obj? instance, Str serviceId) {
		methodArgs	:= scope.registry.autoBuilder.findFuncArgs(scope, method.func, null, instance, serviceId)
		opStack		:= ((RegistryImpl) scope.registry).opStack 
		scope.registry.opStack.push("Calling method", method.qname)
		try 	return method.callOn(instance, methodArgs)
		finally	opStack.pop		
	}
}
