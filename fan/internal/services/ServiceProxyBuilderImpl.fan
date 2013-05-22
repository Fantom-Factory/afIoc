
// TODO: Doc - perThread services should be automatic when proxies are added.
** @since 1.3.0
internal const class ServiceProxyBuilderImpl : ServiceProxyBuilder {
	
	@Inject 
	private const Registry registry
	
	@Inject
	private const PlasticPodCompiler plasticPodCompiler
	
	new make(|This|di) { di(this) }

	** We need the serviceDef as only *it* knows how to build the serviceImpl
	override internal Obj buildProxy(OpTracker tracker, ServiceDef serviceDef) {
		tracker.track("Creating Proxy for service '$serviceDef.serviceId'") |->Obj| {
			serviceId	:= serviceDef.serviceId
			serviceType	:= serviceDef.serviceType
			
			if (!serviceType.isMixin)
				throw IocErr(IocMessages.onlyMixinsCanBeProxied(serviceType))
	
			if (!serviceType.isPublic)
				throw IocErr(IocMessages.proxiedMixinsMustBePublic(serviceType))
			
			model := PlasticClassModel(serviceType.name + "Impl", serviceType.isConst)
			
			model.extendMixin(serviceType)
			model.addField(LazyService#, "lazyService")
	
			serviceType.fields.rw
				.each |field| {
					getBody	:= "((${serviceType.qname}) lazyService.get).${field.name}"
					setBody	:= "((${serviceType.qname}) lazyService.get).${field.name} = it"
					model.overrideField(field, getBody, setBody)
				}

			serviceType.methods.rw
				.findAll { it.isAbstract || it.isVirtual }
				.exclude { Obj#.methods.contains(it) }
				.each |method| {
					params 	:= method.params.join(", ") |param| { param.name }
					body 	:= "((${serviceType.qname}) lazyService.get).${method.name}(${params})"
					model.overrideMethod(method, body)
				}
			
			code 		:= model.toFantomCode
			pod 		:= plasticPodCompiler.compile(tracker, code)
			proxyType 	:= pod.type(model.className)
			lazyField 	:= proxyType.field("lazyService")
			plan 		:= Field:Obj?[lazyField : LazyService(serviceDef, (ObjLocator) registry, serviceType.isConst)]
			ctorFunc 	:= Field.makeSetFunc(plan)
			proxy		:= proxyType.make([ctorFunc])
			
			return proxy
		}
	}
}
